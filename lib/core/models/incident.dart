import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../enums/incident_type.dart';

/// Incident communautaire — CDC V4.1 §7.2
///
/// Remplace `CommunityAlert`, dont le rayon était un `switch` sur la gravité
/// calculé côté client (200/500/1000/2000 m). Le V4.1 découple trois valeurs
/// aux usages contradictoires (§4.1) :
///
///   * `displayRadiusM` — le halo dessiné sur la carte. Il exprime
///     l'incertitude : un signalement communautaire est imprécis (GPS urbain
///     ±10 à 50 m), un trait fin prétendrait une précision que la donnée n'a pas.
///   * `dangerBufferM` + `geometry` — la décision d'évitement au routage.
///     Chirurgicale, et transmise uniquement quand l'incident fait autorité.
///   * le rayon de notification reste côté serveur : le client n'en a pas besoin.
class Incident {
  const Incident({
    required this.id,
    required this.type,
    required this.severity,
    required this.lat,
    required this.lng,
    required this.displayRadiusM,
    required this.reportCount,
    required this.confirmCount,
    required this.clearCount,
    required this.confidenceScore,
    required this.affectsRouting,
    required this.status,
    this.expiredByTimeout = false,
    this.expiresAt,
    this.createdAt,
    this.geometryType,
    this.geometry = const [],
    this.dangerBufferM,
  });

  final int id;
  final IncidentType type;
  final IncidentSeverity severity;
  final double lat;
  final double lng;

  /// Rayon du halo, en mètres — §4.4.
  final int displayRadiusM;

  /// Nombre de signalements indépendants. C'est la confiance (§4.5) et le
  /// facteur dominant de `confidenceScore`.
  final int reportCount;
  final int confirmCount;
  final int clearCount;
  final double confidenceScore;

  /// L'incident a-t-il autorité pour modifier un itinéraire ? (§4.9/§4.11)
  final bool affectsRouting;

  final IncidentStatus status;
  final bool expiredByTimeout;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// Géométrie d'évitement — `corridor` ou `polygon`. Absente tant que
  /// l'incident n'affecte pas le routage : le serveur ne la sérialise pas.
  final String? geometryType;
  final List<gmaps.LatLng> geometry;
  final int? dangerBufferM;

  gmaps.LatLng get position => gmaps.LatLng(lat, lng);

  /// Protection côté client : une réponse ou un cache périmé ne doit jamais
  /// maintenir une alerte sur la carte après son heure d'expiration.
  bool get isExpired => expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  bool get isLive => status.isLive && !isExpired;

  /// Indicateur de fiabilité affiché sur la fiche — §6.5.
  /// 1 signalement → « non confirmé », 3+ → « confirmé ».
  String get reliabilityLabel => reportCount >= 3 ? 'confirmé' : 'non confirmé';

  bool get isConfirmed => reportCount >= 3;

  /// « Signalé par 3 personnes » — jamais « 3 personnes confirment » (§6.7).
  String get reportCountLabel => reportCount > 1
      ? 'Signalé par $reportCount personnes'
      : 'Signalé une fois';

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: (json['id'] as num).toInt(),
      type: IncidentType.fromValue(json['type'] as String?),
      severity: IncidentSeverity.fromValue(json['severity'] as String?),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      displayRadiusM: (json['display_radius_m'] as num?)?.toInt() ?? 200,
      reportCount: (json['report_count'] as num?)?.toInt() ?? 1,
      confirmCount: (json['confirm_count'] as num?)?.toInt() ?? 0,
      clearCount: (json['clear_count'] as num?)?.toInt() ?? 0,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      affectsRouting: json['affects_routing'] as bool? ?? false,
      status: IncidentStatus.fromValue(json['status'] as String?),
      expiredByTimeout: json['expired_by_timeout'] as bool? ?? false,
      expiresAt: _parseDate(json['expires_at']),
      createdAt: _parseDate(json['created_at']),
      geometryType: json['geometry_type'] as String?,
      geometry: _parseGeometry(json['geometry']),
      dangerBufferM: (json['danger_buffer_m'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Le serveur envoie une liste de couples [lat, lng].
  static List<gmaps.LatLng> _parseGeometry(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<List>()
        .where((point) => point.length >= 2)
        .map((point) => gmaps.LatLng(
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ))
        .toList();
  }

  Incident copyWith({
    int? reportCount,
    int? confirmCount,
    int? clearCount,
    bool? affectsRouting,
    IncidentStatus? status,
    bool? expiredByTimeout,
  }) {
    return Incident(
      id: id,
      type: type,
      severity: severity,
      lat: lat,
      lng: lng,
      displayRadiusM: displayRadiusM,
      reportCount: reportCount ?? this.reportCount,
      confirmCount: confirmCount ?? this.confirmCount,
      clearCount: clearCount ?? this.clearCount,
      confidenceScore: confidenceScore,
      affectsRouting: affectsRouting ?? this.affectsRouting,
      status: status ?? this.status,
      expiredByTimeout: expiredByTimeout ?? this.expiredByTimeout,
      expiresAt: expiresAt,
      createdAt: createdAt,
      geometryType: geometryType,
      geometry: geometry,
      dangerBufferM: dangerBufferM,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Incident && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
