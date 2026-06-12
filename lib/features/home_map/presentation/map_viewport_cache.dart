import '../../../core/models/danger_zone.dart';

/// Cache LRU simple pour les résultats de viewport.
/// Clé = grille tronquée (zoom + bbox arrondie) → évite les requêtes redondantes
/// pour des déplacements mineurs de la caméra.
class MapViewportCache {
  static const int _maxEntries = 20;

  final Map<String, List<DangerZone>> _cache = {};
  final List<String> _insertionOrder = [];

  /// Construit une clé de cache à partir des limites visibles et du zoom.
  /// La précision est réduite (~1 km) pour regrouper les viewports proches.
  static String buildKey({
    required double south,
    required double north,
    required double west,
    required double east,
    required int zoom,
  }) {
    const precision = 2;
    return 'z${zoom}_'
        '${south.toStringAsFixed(precision)}_'
        '${north.toStringAsFixed(precision)}_'
        '${west.toStringAsFixed(precision)}_'
        '${east.toStringAsFixed(precision)}';
  }

  List<DangerZone>? get(String key) => _cache[key];

  void set(String key, List<DangerZone> zones) {
    if (_cache.containsKey(key)) {
      _cache[key] = zones;
      return;
    }
    if (_insertionOrder.length >= _maxEntries) {
      final oldest = _insertionOrder.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[key] = zones;
    _insertionOrder.add(key);
  }

  bool contains(String key) => _cache.containsKey(key);

  void invalidate() {
    _cache.clear();
    _insertionOrder.clear();
  }
}
