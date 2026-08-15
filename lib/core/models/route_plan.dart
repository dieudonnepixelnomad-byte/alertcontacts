import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../utils/flexible_polyline.dart';
import 'incident.dart';

/// Mode de transport — CDC V4.1 §6.2
enum TransportMode {
  car('car', 'Voiture', '🚗'),
  pedestrian('pedestrian', 'À pied', '🚶'),
  scooter('scooter', 'Deux-roues', '🛵');

  const TransportMode(this.value, this.label, this.emoji);

  final String value;
  final String label;
  final String emoji;

  static TransportMode fromValue(String? value) {
    for (final mode in TransportMode.values) {
      if (mode.value == value) return mode;
    }
    return TransportMode.car;
  }
}

/// Badge de sécurité d'un itinéraire — CDC V4.1 §6.4
///
/// Le vocabulaire est contraint (§6.7) : on ne promet jamais un « itinéraire
/// sécurisé » ni une « zone évitée à 100 % ». L'évitement peut être partiel,
/// HERE le documente explicitement.
enum RouteSafety {
  avoids('avoids', '✅', 'contourne la zone signalée'),
  partial('partial', '⚠️', 'contournement partiel'),
  crosses('crosses', '🔴', 'traverse la zone signalée');

  const RouteSafety(this.value, this.emoji, this.label);

  final String value;
  final String emoji;
  final String label;

  static RouteSafety fromValue(String? value) {
    for (final safety in RouteSafety.values) {
      if (safety.value == value) return safety;
    }
    return RouteSafety.crosses;
  }
}

/// Un itinéraire proposé — CDC V4.1 §6.4
class RouteOption {
  const RouteOption({
    required this.index,
    required this.label,
    required this.polyline,
    required this.distanceM,
    required this.durationS,
    this.deltaS = 0,
    this.safety = RouteSafety.avoids,
    this.detourExcessive = false,
    this.stillCrossedIncidentIds = const [],
  });

  final int index;

  /// Issu de `routeLabels` — « via A86 ». Fourni par l'API, aucun code à écrire.
  final String label;
  final String polyline;
  final int distanceM;
  final int durationS;

  /// Écart avec l'itinéraire de référence, en secondes.
  final int deltaS;
  final RouteSafety safety;

  /// §5.6 — au-delà de +50 %, on propose sans imposer.
  final bool detourExcessive;
  final List<int> stillCrossedIncidentIds;

  List<gmaps.LatLng> get points => FlexiblePolyline.decode(polyline)
      .map((p) => gmaps.LatLng(p.lat, p.lng))
      .toList();

  factory RouteOption.fromJson(Map<String, dynamic> json, {int fallbackIndex = 0}) {
    return RouteOption(
      index: (json['index'] as num?)?.toInt() ?? fallbackIndex,
      label: json['label'] as String? ?? 'Itinéraire',
      polyline: json['polyline'] as String? ?? '',
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (json['duration_s'] as num?)?.toInt() ?? 0,
      deltaS: (json['delta_s'] as num?)?.toInt() ?? 0,
      safety: RouteSafety.fromValue(json['safety_badge'] as String?),
      detourExcessive: json['detour_excessive'] as bool? ?? false,
      stillCrossedIncidentIds:
          (json['still_crossed'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
    );
  }
}

/// Un incident rencontré sur le trajet — CDC V4.1 §7.4
class RouteIncidentHit {
  const RouteIncidentHit({
    required this.incident,
    required this.minDistanceM,
    required this.distanceFromOriginM,
    required this.headline,
    required this.detail,
  });

  final Incident incident;
  final int minDistanceM;
  final int distanceFromOriginM;

  /// « 🔴 Agression signalée sur ton trajet » — wording fourni par le serveur
  /// pour garantir le respect des règles du §6.7.
  final String headline;

  /// « Signalé par 3 personnes · il y a 12 min »
  final String detail;

  factory RouteIncidentHit.fromJson(Map<String, dynamic> json) {
    return RouteIncidentHit(
      incident: Incident.fromJson(json['incident'] as Map<String, dynamic>),
      minDistanceM: (json['min_distance_m'] as num?)?.toInt() ?? 0,
      distanceFromOriginM: (json['distance_from_origin_m'] as num?)?.toInt() ?? 0,
      headline: json['headline'] as String? ?? 'Alerte sur ton trajet',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Un trajet planifié — CDC V4.1 §7.3
class RoutePlan {
  const RoutePlan({
    required this.id,
    required this.origin,
    required this.destination,
    required this.transportMode,
    required this.polyline,
    required this.distanceM,
    required this.durationS,
    required this.status,
    this.originLabel,
    this.destinationLabel,
    this.alternatives = const [],
    this.selectedIndex = 0,
    this.avoidanceApplied = false,
    this.avoidancePartial = false,
    this.createdAt,
  });

  final int id;
  final gmaps.LatLng origin;
  final gmaps.LatLng destination;
  final String? originLabel;
  final String? destinationLabel;
  final TransportMode transportMode;
  final String polyline;
  final int distanceM;
  final int durationS;
  final List<RouteOption> alternatives;
  final int selectedIndex;
  final bool avoidanceApplied;
  final bool avoidancePartial;
  final String status;
  final DateTime? createdAt;

  List<gmaps.LatLng> get points => FlexiblePolyline.decode(polyline)
      .map((p) => gmaps.LatLng(p.lat, p.lng))
      .toList();

  /// Heure d'arrivée estimée — §6.3.
  DateTime get estimatedArrival => DateTime.now().add(Duration(seconds: durationS));

  factory RoutePlan.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as Map<String, dynamic>? ?? const {};
    final destination = json['destination'] as Map<String, dynamic>? ?? const {};
    final alternatives = json['alternatives'] as List? ?? const [];

    return RoutePlan(
      id: (json['id'] as num).toInt(),
      origin: gmaps.LatLng(
        (origin['lat'] as num?)?.toDouble() ?? 0,
        (origin['lng'] as num?)?.toDouble() ?? 0,
      ),
      destination: gmaps.LatLng(
        (destination['lat'] as num?)?.toDouble() ?? 0,
        (destination['lng'] as num?)?.toDouble() ?? 0,
      ),
      originLabel: origin['label'] as String?,
      destinationLabel: destination['label'] as String?,
      transportMode: TransportMode.fromValue(json['transport_mode'] as String?),
      polyline: json['polyline'] as String? ?? '',
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (json['duration_s'] as num?)?.toInt() ?? 0,
      alternatives: [
        for (var i = 0; i < alternatives.length; i++)
          RouteOption.fromJson(alternatives[i] as Map<String, dynamic>, fallbackIndex: i),
      ],
      selectedIndex: (json['selected_index'] as num?)?.toInt() ?? 0,
      avoidanceApplied: json['avoidance_applied'] as bool? ?? false,
      avoidancePartial: json['avoidance_partial'] as bool? ?? false,
      status: json['status'] as String? ?? 'planned',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// Réponse de `POST /routes/preview` — CDC V4.1 §8.1
class RoutePreview {
  const RoutePreview({
    required this.route,
    required this.incidentsOnRoute,
    required this.destinationInside,
    required this.canAvoid,
    this.message,
  });

  final RoutePlan route;
  final List<RouteIncidentHit> incidentsOnRoute;

  /// §5.6 — la destination est dans la zone signalée : on ne propose pas de
  /// contournement, on prévient.
  final bool destinationInside;
  final bool canAvoid;
  final String? message;

  bool get hasIncidents => incidentsOnRoute.isNotEmpty;

  factory RoutePreview.fromJson(Map<String, dynamic> json) {
    return RoutePreview(
      route: RoutePlan.fromJson(json['route'] as Map<String, dynamic>),
      incidentsOnRoute: (json['incidents_on_route'] as List? ?? const [])
          .map((e) => RouteIncidentHit.fromJson(e as Map<String, dynamic>))
          .toList(),
      destinationInside: json['destination_inside'] as bool? ?? false,
      canAvoid: json['can_avoid'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

/// Réponse de `POST /routes/{id}/avoid` — CDC V4.1 §8.1
class RouteAvoidanceResult {
  const RouteAvoidanceResult({
    required this.route,
    required this.options,
    required this.avoidancePartial,
    required this.incidentsStillCrossed,
    this.message,
  });

  final RoutePlan route;

  /// Triées par le serveur : l'itinéraire sûr en premier, même s'il est plus
  /// long (§6.4).
  final List<RouteOption> options;
  final bool avoidancePartial;
  final List<int> incidentsStillCrossed;
  final String? message;

  /// UC-08 — aucune alternative ne contourne la zone.
  bool get hasNoAlternative => avoidancePartial && incidentsStillCrossed.isNotEmpty;

  factory RouteAvoidanceResult.fromJson(Map<String, dynamic> json) {
    return RouteAvoidanceResult(
      route: RoutePlan.fromJson(json['route'] as Map<String, dynamic>),
      options: (json['options'] as List? ?? const [])
          .map((e) => RouteOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      avoidancePartial: json['avoidance_partial'] as bool? ?? false,
      incidentsStillCrossed: (json['incidents_still_crossed'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      message: json['message'] as String?,
    );
  }
}
