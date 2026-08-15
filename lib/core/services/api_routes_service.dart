import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/route_plan.dart';
import 'api_v1_client.dart';

/// Une destination récente — CDC V4.1 §6.2
class RecentDestination {
  const RecentDestination({required this.position, required this.label});

  final gmaps.LatLng position;
  final String label;

  factory RecentDestination.fromJson(Map<String, dynamic> json) {
    return RecentDestination(
      position: gmaps.LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      label: json['label'] as String? ?? '',
    );
  }
}

/// État du quota de contournement — CDC V4.1 §10.2
class AvoidanceQuota {
  const AvoidanceQuota({required this.used, required this.limit, required this.tier});

  final int used;
  final int limit;
  final String tier;

  bool get isPaid => tier == 'solo' || tier == 'famille';

  int get remaining => isPaid ? -1 : (limit - used).clamp(0, limit);

  factory AvoidanceQuota.fromJson(Map<String, dynamic> json) {
    return AvoidanceQuota(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'free',
    );
  }
}

/// Module Trajets — CDC V4.1 §8.1
///
/// Flutter n'appelle jamais le moteur de routage directement : la clé API
/// reste serveur, la facture reste sous contrôle, et changer de fournisseur
/// n'oblige pas à publier sur les stores (§5.3).
class ApiRoutesService {
  ApiRoutesService({ApiV1Client? client}) : _client = client ?? ApiV1Client();

  final ApiV1Client _client;

  void setBearerToken(String? token) => _client.setBearerToken(token);

  /// Aperçu — 1 appel au moteur, plus la détection locale des incidents.
  Future<RoutePreview> preview({
    required gmaps.LatLng origin,
    required gmaps.LatLng destination,
    String? originLabel,
    String? destinationLabel,
    TransportMode transportMode = TransportMode.car,
  }) async {
    final data = await _client.post('/routes/preview', body: {
      'origin': {
        'lat': origin.latitude,
        'lng': origin.longitude,
        if (originLabel != null) 'label': originLabel,
      },
      'destination': {
        'lat': destination.latitude,
        'lng': destination.longitude,
        if (destinationLabel != null) 'label': destinationLabel,
      },
      'transport_mode': transportMode.value,
    });

    return RoutePreview.fromJson(data as Map<String, dynamic>);
  }

  /// Contournement — second appel, uniquement sur action explicite (§5.4).
  ///
  /// Lève [QuotaExceededException] quand le tier Gratuit a épuisé ses trois
  /// contournements de gravité Faible/Moyen du mois. La gravité Élevé n'est
  /// jamais bloquée.
  Future<RouteAvoidanceResult> avoid({
    required int routeId,
    required List<int> incidentIds,
  }) async {
    final data = await _client.post('/routes/$routeId/avoid', body: {
      'incident_ids': incidentIds,
    });

    return RouteAvoidanceResult.fromJson(data as Map<String, dynamic>);
  }

  Future<RoutePlan> select({required int routeId, required int routeIndex}) async {
    final data = await _client.post('/routes/$routeId/select', body: {
      'route_index': routeIndex,
    });

    return RoutePlan.fromJson(data as Map<String, dynamic>);
  }

  Future<RoutePlan> start(int routeId) => _transition(routeId, 'start');

  Future<RoutePlan> end(int routeId) => _transition(routeId, 'end');

  Future<RoutePlan> cancel(int routeId) => _transition(routeId, 'cancel');

  Future<List<RoutePlan>> history() async {
    final data = await _client.get('/routes/history');

    return (data as List? ?? const [])
        .map((e) => RoutePlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecentDestination>> recentDestinations() async {
    final data = await _client.get('/routes/recent-destinations');

    return (data as List? ?? const [])
        .map((e) => RecentDestination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AvoidanceQuota> avoidanceQuota() async {
    final data = await _client.get('/routes/avoidance-quota');

    return AvoidanceQuota.fromJson(data as Map<String, dynamic>);
  }

  Future<RoutePlan> _transition(int routeId, String action) async {
    final data = await _client.post('/routes/$routeId/$action');

    return RoutePlan.fromJson(data as Map<String, dynamic>);
  }
}
