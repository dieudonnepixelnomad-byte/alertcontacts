import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../enums/incident_type.dart';
import '../models/incident.dart';
import '../models/my_community_report.dart';
import 'api_v1_client.dart';

/// Résultat de la détection de doublon — CDC V4.1 §6.6
class DuplicateCheck {
  const DuplicateCheck({required this.found, this.incident});

  final bool found;
  final Incident? incident;
}

/// Signalements et incidents communautaires — CDC V4.1 §8.2
class ApiIncidentsService {
  ApiIncidentsService({ApiV1Client? client}) : _client = client ?? ApiV1Client();

  final ApiV1Client _client;

  void setBearerToken(String? token) => _client.setBearerToken(token);

  /// Incidents actifs dans la zone visible — sert le halo d'affichage (§4.4).
  Future<List<Incident>> getIncidentsInBounds(gmaps.LatLngBounds bounds) async {
    final bbox = '${bounds.southwest.latitude},${bounds.southwest.longitude},'
        '${bounds.northeast.latitude},${bounds.northeast.longitude}';

    final data = await _client.get('/incidents', query: {'bbox': bbox});

    return (data as List? ?? const [])
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Incident> getIncident(int id) async {
    final data = await _client.get('/incidents/$id');

    return Incident.fromJson(data as Map<String, dynamic>);
  }

  /// Signalements créés par le compte connecté, quelle que soit sa position.
  Future<List<MyCommunityReport>> getMyReports() async {
    final data = await _client.get('/reports/mine');

    return (data as List? ?? const [])
        .map((e) => MyCommunityReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retire le signalement du compte connecté. L'incident agrégé est recalculé
  /// côté serveur lorsqu'il est aussi porté par d'autres témoignages.
  Future<void> deleteMyReport(int reportId) async {
    await _client.delete('/reports/$reportId');
  }

  /// Création d'un signalement — §8.2.
  ///
  /// L'utilisateur ne choisit ni rayon ni géométrie (§4.6) : on transmet la
  /// précision du fix et les derniers mètres de sa trace, le serveur en déduit
  /// un corridor ou un polygone serré.
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
    final data = await _client.post('/reports', body: {
      'type': type.value,
      if (severity != null) 'severity': severity.value,
      'lat': lat,
      'lng': lng,
      if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
      if (gpsTrace != null && gpsTrace.isNotEmpty)
        'gps_trace': gpsTrace
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      'was_moving': wasMoving,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'visibility': contactsOnly ? 'circle' : 'public',
    });

    final payload = data as Map<String, dynamic>;

    return Incident.fromJson(payload['incident'] as Map<String, dynamic>);
  }

  /// Un incident compatible existe-t-il déjà ici ? — §6.6.
  ///
  /// Transformer un doublon en confirmation renforce la confiance de
  /// l'incident au lieu de polluer la carte.
  Future<DuplicateCheck> checkDuplicate({
    required IncidentType type,
    required double lat,
    required double lng,
  }) async {
    final data = await _client.get('/reports/duplicate-check', query: {
      'type': type.value,
      'lat': lat.toString(),
      'lng': lng.toString(),
    }) as Map<String, dynamic>;

    final incident = data['incident'];

    return DuplicateCheck(
      found: data['found'] as bool? ?? false,
      incident: incident is Map<String, dynamic> ? Incident.fromJson(incident) : null,
    );
  }

  /// « Je le vois aussi ».
  Future<Incident> confirm(int incidentId) => _interact(incidentId, 'confirm');

  /// « C'est terminé » — §4.7a.
  Future<Incident> clear(int incidentId) => _interact(incidentId, 'clear');

  Future<void> reportAbuse(int incidentId, {String? reason}) async {
    await _client.post('/incidents/$incidentId/report-abuse', body: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<Incident> _interact(int incidentId, String action) async {
    final data = await _client.post('/incidents/$incidentId/$action') as Map<String, dynamic>;

    return Incident.fromJson(data['incident'] as Map<String, dynamic>);
  }
}
