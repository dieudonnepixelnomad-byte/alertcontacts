import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/location_point.dart';
import 'location_service.dart';

/// Trace GPS récente du porteur — CDC V4.1 §4.6 cas 1
///
/// « Le signaleur est en déplacement : sa trace GPS récente est déjà remontée.
/// **Les 100 derniers mètres de sa propre trace *sont* la géométrie de la
/// voie.** » Ils sont repris tels quels comme polyligne du corridor.
///
/// Zéro appel externe, zéro coût, et géométrie exacte plutôt qu'approximée —
/// là où un disque autour du point exclurait aussi la rue parallèle.
///
/// Ce recorder se contente d'écouter le flux de positions que
/// [LocationService] produit déjà : il n'ouvre aucun capteur supplémentaire et
/// ne change rien à la consommation de batterie.
class GpsTraceRecorder {
  GpsTraceRecorder._internal();

  static final GpsTraceRecorder _instance = GpsTraceRecorder._internal();

  factory GpsTraceRecorder() => _instance;

  /// Longueur de trace conservée, alignée sur `incidents.geometry.corridor_length_m`.
  static const double maxTraceLengthM = 150;

  /// Au-delà, la trace est trop vieille pour décrire la voie où on se trouve.
  static const Duration maxAge = Duration(minutes: 5);

  /// Sous ce seuil, le porteur est considéré immobile : la trace ne décrit
  /// plus une voie mais un point, et le serveur retombe sur un polygone serré.
  static const double minTraceLengthM = 20;

  final List<_TracePoint> _points = [];
  StreamSubscription<LocationPoint>? _subscription;

  void start() {
    _subscription ??= LocationService().locationStream.listen(_record);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _points.clear();
  }

  void _record(LocationPoint point) {
    _points.add(_TracePoint(
      lat: point.latitude,
      lng: point.longitude,
      at: DateTime.now(),
    ));

    _prune();
  }

  /// Ne garde que ce qui est à la fois récent et dans les derniers mètres.
  void _prune() {
    final cutoff = DateTime.now().subtract(maxAge);
    _points.removeWhere((p) => p.at.isBefore(cutoff));

    var cumulative = 0.0;
    var keepFrom = 0;

    for (var i = _points.length - 1; i > 0; i--) {
      cumulative += _haversine(_points[i - 1], _points[i]);

      if (cumulative >= maxTraceLengthM) {
        keepFrom = i - 1;
        break;
      }
    }

    if (keepFrom > 0) {
      _points.removeRange(0, keepFrom);
    }
  }

  /// Trace exploitable pour construire un corridor, ou `null` si le porteur
  /// est à l'arrêt ou piéton — cas 2 du §4.6, repli serveur sur un polygone.
  List<gmaps.LatLng>? currentTrace() {
    _prune();

    if (_points.length < 2) return null;

    var length = 0.0;
    for (var i = 1; i < _points.length; i++) {
      length += _haversine(_points[i - 1], _points[i]);
    }

    if (length < minTraceLengthM) return null;

    return _points.map((p) => gmaps.LatLng(p.lat, p.lng)).toList();
  }

  /// Le porteur s'est-il déplacé récemment ? Alimente `was_moving` (§4.8) :
  /// à l'arrêt, la position est plus fiable.
  bool get isMoving => currentTrace() != null;

  static double _haversine(_TracePoint a, _TracePoint b) {
    const earthRadiusM = 6371000.0;

    final dLat = _toRadians(b.lat - a.lat);
    final dLng = _toRadians(b.lng - a.lng);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(a.lat)) *
            math.cos(_toRadians(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadiusM * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

class _TracePoint {
  const _TracePoint({required this.lat, required this.lng, required this.at});

  final double lat;
  final double lng;
  final DateTime at;
}
