import 'dart:math';

class LocationUtils {
  /// Calculates the distance between two points in kilometers.
  static double getDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Radius of the earth in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final d = R * c; // Distance in km
    return d * 1000; // Distance in meters
  }

  static double _deg2rad(double deg) {
    return deg * (pi / 180);
  }
}