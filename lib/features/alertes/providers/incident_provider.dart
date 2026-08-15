import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../core/enums/incident_type.dart';
import '../../../core/models/incident.dart';
import '../../../core/services/api_incidents_service.dart';
import '../../../core/services/prefs_service.dart';

/// Incidents communautaires — CDC V4.1 §4
///
/// Remplace la partie « alertes communautaires » d'`AlertProvider`, qui
/// travaillait sur des `CommunityAlert` à rayon dérivé de la gravité et
/// appelait le service HTTP en direct.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._service, this._prefs) {
    _syncToken();
  }

  final ApiIncidentsService _service;
  final PrefsService _prefs;

  final Map<int, Incident> _incidents = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Incident> get incidents => _incidents.values
      .where((i) => i.status.isLive)
      .toList()
    ..sort((a, b) => b.severity.rank.compareTo(a.severity.rank));

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Incident? byId(int id) => _incidents[id];

  Future<void> _syncToken() async {
    _service.setBearerToken(await _prefs.getBearerToken());
  }

  /// Charge les incidents de la zone visible — appelé à chaque `onCameraIdle`.
  Future<void> loadForBounds(gmaps.LatLngBounds bounds) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _syncToken();
      final fetched = await _service.getIncidentsInBounds(bounds);

      // Fusion plutôt que remplacement : sortir de la zone visible ne doit pas
      // faire disparaître un incident qu'on affiche encore ailleurs.
      for (final incident in fetched) {
        _incidents[incident.id] = incident;
      }

      // §5.6 — un incident expiré ou résolu est retiré silencieusement.
      // L'absence de danger n'est pas un événement.
      _incidents.removeWhere((_, incident) => !incident.status.isLive);
    } catch (e) {
      log('[IncidentProvider] loadForBounds: $e');
      _errorMessage = 'Impossible de charger les alertes pour le moment.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Incident?> refreshIncident(int id) async {
    try {
      await _syncToken();
      final incident = await _service.getIncident(id);
      _incidents[incident.id] = incident;
      notifyListeners();
      return incident;
    } catch (e) {
      log('[IncidentProvider] refreshIncident($id): $e');
      return null;
    }
  }

  /// Détection de doublon avant envoi — §6.6.
  Future<DuplicateCheck?> checkDuplicate({
    required IncidentType type,
    required double lat,
    required double lng,
  }) async {
    try {
      await _syncToken();
      return await _service.checkDuplicate(type: type, lat: lat, lng: lng);
    } catch (e) {
      // Un échec de la détection ne doit jamais bloquer un signalement :
      // mieux vaut un doublon qu'une alerte perdue.
      log('[IncidentProvider] checkDuplicate: $e');
      return null;
    }
  }

  /// Envoi d'un signalement. Le serveur renvoie l'incident résultant, qu'il
  /// vienne d'être créé ou que le signalement ait fusionné (§4.5).
  Future<Incident> submitReport({
    required IncidentType type,
    required double lat,
    required double lng,
    IncidentSeverity? severity,
    int? gpsAccuracyM,
    List<gmaps.LatLng>? gpsTrace,
    bool wasMoving = false,
    int? speedKmh,
    String? comment,
    bool contactsOnly = false,
  }) async {
    await _syncToken();

    final incident = await _service.submitReport(
      type: type,
      lat: lat,
      lng: lng,
      severity: severity,
      gpsAccuracyM: gpsAccuracyM,
      gpsTrace: gpsTrace,
      wasMoving: wasMoving,
      speedKmh: speedKmh,
      comment: comment,
      contactsOnly: contactsOnly,
    );

    _incidents[incident.id] = incident;
    notifyListeners();

    return incident;
  }

  /// « Je le vois aussi ».
  Future<Incident?> confirm(int incidentId) => _interact(() => _service.confirm(incidentId));

  /// « C'est terminé » — §4.7a.
  Future<Incident?> clear(int incidentId) => _interact(() => _service.clear(incidentId));

  Future<bool> reportAbuse(int incidentId, {String? reason}) async {
    try {
      await _syncToken();
      await _service.reportAbuse(incidentId, reason: reason);
      return true;
    } catch (e) {
      log('[IncidentProvider] reportAbuse: $e');
      return false;
    }
  }

  Future<Incident?> _interact(Future<Incident> Function() action) async {
    try {
      await _syncToken();
      final incident = await action();

      if (incident.status.isLive) {
        _incidents[incident.id] = incident;
      } else {
        _incidents.remove(incident.id);
      }

      notifyListeners();
      return incident;
    } catch (e) {
      log('[IncidentProvider] interaction: $e');
      _errorMessage = 'Action impossible pour le moment.';
      notifyListeners();
      return null;
    }
  }
}
