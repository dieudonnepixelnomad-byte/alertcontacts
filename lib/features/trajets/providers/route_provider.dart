import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../core/models/route_plan.dart';
import '../../../core/services/api_routes_service.dart';
import '../../../core/services/api_v1_client.dart';
import '../../../core/services/prefs_service.dart';

enum RouteFlowStatus { idle, loading, ready, avoiding, error }

/// Module Trajets — CDC V4.1 §5
///
/// Économie d'appels au moteur de routage, qui est une décision produit :
///   * aperçu        → 1 appel
///   * détection HIT → 0 appel (calcul serveur local)
///   * contournement → 1 appel, uniquement si l'utilisateur tape « Contourner »
class RouteProvider extends ChangeNotifier {
  RouteProvider(this._service, this._prefs);

  final ApiRoutesService _service;
  final PrefsService _prefs;

  RouteFlowStatus _status = RouteFlowStatus.idle;
  String? _errorMessage;

  RoutePreview? _preview;
  List<RouteOption> _options = const [];
  int _selectedOptionIndex = 0;
  List<RecentDestination> _recentDestinations = const [];
  AvoidanceQuota? _quota;

  /// Renseigné quand le serveur refuse un contournement faute de quota :
  /// l'écran affiche alors le paywall du §10.4.
  QuotaExceededException? _quotaBlock;

  RouteFlowStatus get status => _status;
  String? get errorMessage => _errorMessage;
  RoutePreview? get preview => _preview;
  RoutePlan? get route => _preview?.route;
  List<RouteOption> get options => _options;
  int get selectedOptionIndex => _selectedOptionIndex;
  List<RecentDestination> get recentDestinations => _recentDestinations;
  AvoidanceQuota? get quota => _quota;
  QuotaExceededException? get quotaBlock => _quotaBlock;

  List<RouteIncidentHit> get incidentsOnRoute => _preview?.incidentsOnRoute ?? const [];
  bool get hasIncidents => incidentsOnRoute.isNotEmpty;

  /// Le tracé actuellement affiché sur la carte.
  List<gmaps.LatLng> get activePoints =>
      _options.isNotEmpty ? _options[_selectedOptionIndex].points : (route?.points ?? const []);

  /// Trajet démarré et non terminé/annulé — utilisé pour le bandeau
  /// « trajet en cours » sur la carte d'accueil.
  bool get isActive => route?.status == 'active';

  Future<void> _syncToken() async {
    _service.setBearerToken(await _prefs.getBearerToken());
  }

  /// Étape 2 + 3 — calcul de l'itinéraire et détection des incidents.
  Future<RoutePreview?> loadPreview({
    required gmaps.LatLng origin,
    required gmaps.LatLng destination,
    String? originLabel,
    String? destinationLabel,
    TransportMode transportMode = TransportMode.car,
  }) async {
    _status = RouteFlowStatus.loading;
    _errorMessage = null;
    _quotaBlock = null;
    notifyListeners();

    try {
      await _syncToken();

      final preview = await _service.preview(
        origin: origin,
        destination: destination,
        originLabel: originLabel,
        destinationLabel: destinationLabel,
        transportMode: transportMode,
      );

      _preview = preview;
      _options = preview.route.alternatives;
      _selectedOptionIndex = preview.route.selectedIndex;
      _status = RouteFlowStatus.ready;
      notifyListeners();

      return preview;
    } catch (e) {
      log('[RouteProvider] loadPreview: $e');
      // §9.1 — hors ligne ou moteur indisponible : jamais d'écran bloquant.
      // On garde le dernier itinéraire en mémoire et on affiche un bandeau.
      _errorMessage = "Impossible de calculer cet itinéraire pour l'instant.";
      _status = _preview != null ? RouteFlowStatus.ready : RouteFlowStatus.error;
      notifyListeners();

      return null;
    }
  }

  /// Étape 5 — recalcul avec contournement, sur action explicite.
  Future<RouteAvoidanceResult?> avoidIncidents(List<int> incidentIds) async {
    final currentRoute = route;

    if (currentRoute == null || incidentIds.isEmpty) return null;

    _status = RouteFlowStatus.avoiding;
    _errorMessage = null;
    _quotaBlock = null;
    notifyListeners();

    try {
      await _syncToken();

      final result = await _service.avoid(
        routeId: currentRoute.id,
        incidentIds: incidentIds,
      );

      _options = result.options;
      _selectedOptionIndex = 0; // le serveur trie l'itinéraire sûr en premier
      _status = RouteFlowStatus.ready;
      notifyListeners();

      return result;
    } on QuotaExceededException catch (e) {
      // §10.4 — le paywall apparaît au pic de motivation
      log('[RouteProvider] quota de contournement épuisé: ${e.used}/${e.limit}');
      _quotaBlock = e;
      _status = RouteFlowStatus.ready;
      notifyListeners();

      return null;
    } catch (e) {
      log('[RouteProvider] avoidIncidents: $e');
      _errorMessage = 'Aucun itinéraire ne contourne cette zone pour le moment.';
      _status = RouteFlowStatus.ready;
      notifyListeners();

      return null;
    }
  }

  /// Sélection d'un itinéraire dans la bottom sheet — §6.4.
  Future<void> selectOption(int index) async {
    if (index < 0 || index >= _options.length) return;

    _selectedOptionIndex = index;
    notifyListeners();

    final currentRoute = route;
    if (currentRoute == null) return;

    try {
      await _syncToken();
      await _service.select(routeId: currentRoute.id, routeIndex: _options[index].index);
    } catch (e) {
      // La sélection locale reste valable même si la persistance échoue :
      // l'utilisateur voit son choix appliqué sur la carte.
      log('[RouteProvider] selectOption: $e');
    }
  }

  /// Démarre le trajet — c'est ce passage en `active` qui arme la
  /// surveillance serveur du §5.5.
  Future<bool> startRoute() => _transition((id) => _service.start(id));

  Future<bool> endRoute() => _transition((id) => _service.end(id));

  Future<bool> cancelRoute() => _transition((id) => _service.cancel(id));

  Future<void> loadRecentDestinations() async {
    try {
      await _syncToken();
      _recentDestinations = await _service.recentDestinations();
      notifyListeners();
    } catch (e) {
      log('[RouteProvider] loadRecentDestinations: $e');
    }
  }

  Future<void> loadQuota() async {
    try {
      await _syncToken();
      _quota = await _service.avoidanceQuota();
      notifyListeners();
    } catch (e) {
      log('[RouteProvider] loadQuota: $e');
    }
  }

  Future<List<RoutePlan>> loadHistory() async {
    try {
      await _syncToken();
      return await _service.history();
    } catch (e) {
      log('[RouteProvider] loadHistory: $e');
      return const [];
    }
  }

  void clearQuotaBlock() {
    _quotaBlock = null;
    notifyListeners();
  }

  void reset() {
    _preview = null;
    _options = const [];
    _selectedOptionIndex = 0;
    _quotaBlock = null;
    _errorMessage = null;
    _status = RouteFlowStatus.idle;
    notifyListeners();
  }

  Future<bool> _transition(Future<RoutePlan> Function(int routeId) action) async {
    final currentRoute = route;

    if (currentRoute == null) return false;

    try {
      await _syncToken();
      final updated = await action(currentRoute.id);

      _preview = RoutePreview(
        route: updated,
        incidentsOnRoute: _preview?.incidentsOnRoute ?? const [],
        destinationInside: _preview?.destinationInside ?? false,
        canAvoid: _preview?.canAvoid ?? false,
        message: _preview?.message,
      );

      notifyListeners();
      return true;
    } catch (e) {
      log('[RouteProvider] transition: $e');
      return false;
    }
  }
}
