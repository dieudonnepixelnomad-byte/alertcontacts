// lib/core/fakes/fake_geocoding_service.dart
import '../models/safe_zone.dart';

class FakeGeocodingService {
  Future<String?> reverseGeocode(LatLng pos) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // renvoie une adresse fake
    return 'Adresse approximative, ${pos.lat.toStringAsFixed(5)}, ${pos.lng.toStringAsFixed(5)}';
  }

  Future<LatLng?> geocode(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.trim().isEmpty) return null;
    // renvoie un point fake “différent” en fonction de la longueur
    final base = 3.871; // fake seed
    return LatLng(base + query.length / 1000.0, 11.515 + query.length / 1500.0);
  }
}
