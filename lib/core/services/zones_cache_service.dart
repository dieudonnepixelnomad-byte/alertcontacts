import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import '../models/danger_zone.dart';
import '../models/safe_zone.dart';
import '../models/zone.dart';

/// Service de cache intelligent pour les zones de danger et de sécurité
class ZonesCacheService {
  static final ZonesCacheService _instance = ZonesCacheService._internal();
  factory ZonesCacheService() => _instance;
  ZonesCacheService._internal();

  // Cache des zones de danger par région
  final Map<String, CachedDangerZones> _dangerZonesCache = {};
  
  // Cache des zones de sécurité de l'utilisateur
  CachedSafeZones? _safeZonesCache;
  
  // Durée de validité du cache (5 minutes pour les zones de danger, 10 minutes pour les zones de sécurité)
  static const Duration _dangerZonesCacheDuration = Duration(minutes: 5);
  static const Duration _safeZonesCacheDuration = Duration(minutes: 10);
  
  // Rayon de tolérance pour considérer qu'une région est déjà en cache (en km)
  static const double _regionToleranceKm = 1.0;

  /// Obtenir les zones de danger depuis le cache ou déclencher un rechargement
  Future<List<DangerZone>?> getCachedDangerZones({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final regionKey = _generateRegionKey(lat, lng, radiusKm);
    final cachedData = _dangerZonesCache[regionKey];
    
    if (cachedData != null && !cachedData.isExpired) {
      log('ZonesCacheService: Returning cached danger zones for region $regionKey');
      return cachedData.zones;
    }
    
    // Vérifier si une région proche est déjà en cache
    final nearbyCache = _findNearbyDangerZonesCache(lat, lng, radiusKm);
    if (nearbyCache != null && !nearbyCache.isExpired) {
      log('ZonesCacheService: Returning nearby cached danger zones');
      return nearbyCache.zones;
    }
    
    log('ZonesCacheService: No valid cache found for danger zones at ($lat, $lng)');
    return null;
  }

  /// Mettre en cache les zones de danger pour une région
  void cacheDangerZones({
    required double lat,
    required double lng,
    required double radiusKm,
    required List<DangerZone> zones,
  }) {
    final regionKey = _generateRegionKey(lat, lng, radiusKm);
    _dangerZonesCache[regionKey] = CachedDangerZones(
      zones: zones,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      cachedAt: DateTime.now(),
    );
    
    log('ZonesCacheService: Cached ${zones.length} danger zones for region $regionKey');
    
    // Nettoyer les anciens caches
    _cleanupExpiredDangerZones();
  }

  /// Obtenir les zones de sécurité depuis le cache
  List<SafeZone>? getCachedSafeZones() {
    if (_safeZonesCache != null && !_safeZonesCache!.isExpired) {
      log('ZonesCacheService: Returning cached safe zones');
      return _safeZonesCache!.zones;
    }
    
    log('ZonesCacheService: No valid cache found for safe zones');
    return null;
  }

  /// Mettre en cache les zones de sécurité
  void cacheSafeZones(List<SafeZone> zones) {
    _safeZonesCache = CachedSafeZones(
      zones: zones,
      cachedAt: DateTime.now(),
    );
    
    log('ZonesCacheService: Cached ${zones.length} safe zones');
  }

  /// Obtenir les zones unifiées depuis le cache
  List<Zone>? getCachedUnifiedZones() {
    if (_safeZonesCache != null && !_safeZonesCache!.isExpired) {
      log('ZonesCacheService: Returning cached unified zones');
      return _safeZonesCache!.zones.map((safeZone) => Zone.fromSafeZone(safeZone)).toList();
    }
    
    log('ZonesCacheService: No valid cache found for unified zones');
    return null;
  }

  /// Mettre en cache les zones unifiées
  void cacheUnifiedZones(List<Zone> zones) {
    // Extraire les zones de sécurité et les convertir en SafeZone
    final safeZones = zones
        .where((zone) => zone.type == ZoneType.safe)
        .map((zone) => SafeZone(
          id: zone.id,
          name: zone.name,
          iconKey: zone.iconKey ?? 'home',
          center: zone.center,
          radiusMeters: zone.radiusMeters,
          address: zone.address,
          memberIds: zone.memberIds ?? [],
          createdAt: zone.createdAt,
          updatedAt: zone.updatedAt,
        ))
        .toList();
    
    if (safeZones.isNotEmpty) {
      cacheSafeZones(safeZones);
    }
  }

  /// Invalider le cache des zones de danger pour une région
  void invalidateDangerZonesCache({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final regionKey = _generateRegionKey(lat, lng, radiusKm);
    _dangerZonesCache.remove(regionKey);
    log('ZonesCacheService: Invalidated danger zones cache for region $regionKey');
  }

  /// Invalider le cache des zones de sécurité
  void invalidateSafeZonesCache() {
    _safeZonesCache = null;
    log('ZonesCacheService: Invalidated safe zones cache');
  }

  /// Invalider tout le cache
  void invalidateAllCache() {
    _dangerZonesCache.clear();
    _safeZonesCache = null;
    log('ZonesCacheService: Invalidated all cache');
  }

  /// Vérifier si le cache des zones de danger est valide pour une région
  bool isDangerZonesCacheValid({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final regionKey = _generateRegionKey(lat, lng, radiusKm);
    final cachedData = _dangerZonesCache[regionKey];
    return cachedData != null && !cachedData.isExpired;
  }

  /// Vérifier si le cache des zones de sécurité est valide
  bool isSafeZonesCacheValid() {
    return _safeZonesCache != null && !_safeZonesCache!.isExpired;
  }

  /// Générer une clé unique pour une région
  String _generateRegionKey(double lat, double lng, double radiusKm) {
    // Arrondir les coordonnées pour créer des "buckets" de cache
    final roundedLat = (lat * 1000).round() / 1000;
    final roundedLng = (lng * 1000).round() / 1000;
    final roundedRadius = (radiusKm * 10).round() / 10;
    return '${roundedLat}_${roundedLng}_${roundedRadius}';
  }

  /// Trouver un cache de zones de danger proche
  CachedDangerZones? _findNearbyDangerZonesCache(double lat, double lng, double radiusKm) {
    for (final cachedData in _dangerZonesCache.values) {
      final distance = _calculateDistance(lat, lng, cachedData.lat, cachedData.lng);
      
      // Si la distance est dans la tolérance et que le rayon est similaire
      if (distance <= _regionToleranceKm && 
          (cachedData.radiusKm - radiusKm).abs() <= 1.0) {
        return cachedData;
      }
    }
    return null;
  }

  /// Calculer la distance entre deux points en km
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convertir les degrés en radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Nettoyer les caches expirés des zones de danger
  void _cleanupExpiredDangerZones() {
    final expiredKeys = <String>[];
    
    for (final entry in _dangerZonesCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _dangerZonesCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      log('ZonesCacheService: Cleaned up ${expiredKeys.length} expired danger zone caches');
    }
  }

  /// Obtenir des statistiques sur le cache
  Map<String, dynamic> getCacheStats() {
    final dangerZonesCount = _dangerZonesCache.length;
    final validDangerZones = _dangerZonesCache.values.where((cache) => !cache.isExpired).length;
    final hasSafeZones = _safeZonesCache != null;
    final safeZonesValid = _safeZonesCache != null && !_safeZonesCache!.isExpired;
    
    return {
      'dangerZonesRegions': dangerZonesCount,
      'validDangerZonesRegions': validDangerZones,
      'hasSafeZonesCache': hasSafeZones,
      'safeZonesCacheValid': safeZonesValid,
    };
  }
}

/// Classe pour stocker les zones de danger en cache
class CachedDangerZones {
  final List<DangerZone> zones;
  final double lat;
  final double lng;
  final double radiusKm;
  final DateTime cachedAt;

  CachedDangerZones({
    required this.zones,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.cachedAt,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ZonesCacheService._dangerZonesCacheDuration;
}

/// Classe pour stocker les zones de sécurité en cache
class CachedSafeZones {
  final List<SafeZone> zones;
  final DateTime cachedAt;

  CachedSafeZones({
    required this.zones,
    required this.cachedAt,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ZonesCacheService._safeZonesCacheDuration;
}