import 'dart:math' as math;

import '../models/contact_location.dart';
import '../models/safe_zone.dart';

/// Détermine si une position permet réellement de rassurer l'utilisateur.
/// Une zone créée ou une position ancienne ne suffisent pas.
class SafetyAhaService {
  static const maximumLocationAge = Duration(minutes: 10);
  static const maximumLocationAccuracyMeters = 100.0;

  SafetyPresence? findConfirmedPresence({
    required String contactId,
    required ContactLocation latestLocation,
    required List<SafeZone> zones,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    if (referenceTime.difference(latestLocation.capturedAtDevice) >
            maximumLocationAge ||
        latestLocation.accuracy > maximumLocationAccuracyMeters) {
      return null;
    }

    for (final zone in zones) {
      // La zone doit être attribuée à ce proche : aucune déduction à partir
      // d'une zone appartenant seulement à l'utilisateur courant.
      if (!zone.memberIds.contains(contactId)) continue;

      final distanceMeters = _distanceMeters(
        latestLocation.latitude,
        latestLocation.longitude,
        zone.center.lat,
        zone.center.lng,
      );
      if (distanceMeters <= zone.radiusMeters) {
        return SafetyPresence(zone: zone, distanceMeters: distanceMeters);
      }
    }
    return null;
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusMeters = 6371000.0;
    final deltaLat = _toRadians(lat2 - lat1);
    final deltaLng = _toRadians(lng2 - lng1);
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

class SafetyPresence {
  const SafetyPresence({required this.zone, required this.distanceMeters});

  final SafeZone zone;
  final double distanceMeters;
}
