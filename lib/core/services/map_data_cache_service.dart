// lib/core/services/map_data_cache_service.dart
import 'dart:async';
import 'dart:developer';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/danger_zone.dart';
import '../models/safe_zone.dart';

/// Classe simple pour représenter une position géographique
class CachedPosition {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  CachedPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Service de cache pour les données de la carte
/// 
/// Ce service évite les rechargements inutiles des données
/// et maintient l'état de la carte entre les navigations
class MapDataCacheService {
  static final MapDataCacheService _instance = MapDataCacheService._internal();
  factory MapDataCacheService() => _instance;
  MapDataCacheService._internal();

  // Cache des données
  List<DangerZone>? _cachedDangerZones;
  List<SafeZone>? _cachedSafeZones;
  CachedPosition? _cachedPosition;
  gmaps.CameraPosition? _cachedCameraPosition;
  
  // Timestamps pour la validité du cache
  DateTime? _dangerZonesCacheTime;
  DateTime? _safeZonesCacheTime;
  DateTime? _positionCacheTime;
  
  // Configuration du cache
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const Duration _positionCacheValidityDuration = Duration(minutes: 2);
  
  // État d'initialisation
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Getters pour l'état
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get hasValidDangerZonesCache => _isDangerZonesCacheValid();
  bool get hasValidSafeZonesCache => _isSafeZonesCacheValid();
  bool get hasValidPositionCache => _isPositionCacheValid();
  
  // Getters pour les données cachées
  List<DangerZone>? get cachedDangerZones => hasValidDangerZonesCache ? _cachedDangerZones : null;
  List<SafeZone>? get cachedSafeZones => hasValidSafeZonesCache ? _cachedSafeZones : null;
  CachedPosition? get cachedPosition => hasValidPositionCache ? _cachedPosition : null;
  gmaps.CameraPosition? get cachedCameraPosition => _cachedCameraPosition;
  
  /// Vérifier si le cache des zones de danger est valide
  bool _isDangerZonesCacheValid() {
    if (_cachedDangerZones == null || _dangerZonesCacheTime == null) return false;
    return DateTime.now().difference(_dangerZonesCacheTime!) < _cacheValidityDuration;
  }
  
  /// Vérifier si le cache des zones de sécurité est valide
  bool _isSafeZonesCacheValid() {
    if (_cachedSafeZones == null || _safeZonesCacheTime == null) return false;
    return DateTime.now().difference(_safeZonesCacheTime!) < _cacheValidityDuration;
  }
  
  /// Vérifier si le cache de position est valide
  bool _isPositionCacheValid() {
    if (_cachedPosition == null || _positionCacheTime == null) return false;
    return DateTime.now().difference(_positionCacheTime!) < _positionCacheValidityDuration;
  }
  
  /// Marquer le service comme initialisé
  void markAsInitialized() {
    _isInitialized = true;
    _isInitializing = false;
    log('MapDataCacheService: Marqué comme initialisé');
  }
  
  /// Marquer le service comme en cours d'initialisation
  void markAsInitializing() {
    _isInitializing = true;
    log('MapDataCacheService: Marqué comme en cours d\'initialisation');
  }
  
  /// Mettre en cache les zones de danger
  void cacheDangerZones(List<DangerZone> zones) {
    _cachedDangerZones = List.from(zones);
    _dangerZonesCacheTime = DateTime.now();
    log('MapDataCacheService: ${zones.length} zones de danger mises en cache');
  }
  
  /// Mettre en cache les zones de sécurité
  void cacheSafeZones(List<SafeZone> zones) {
    _cachedSafeZones = List.from(zones);
    _safeZonesCacheTime = DateTime.now();
    log('MapDataCacheService: ${zones.length} zones de sécurité mises en cache');
  }
  
  /// Mettre en cache la position
  void cachePosition(CachedPosition position) {
    _cachedPosition = position;
    _positionCacheTime = DateTime.now();
    log('MapDataCacheService: Position mise en cache (${position.latitude}, ${position.longitude})');
  }
  
  /// Mettre en cache la position de la caméra
  void cacheCameraPosition(gmaps.CameraPosition cameraPosition) {
    _cachedCameraPosition = cameraPosition;
    log('MapDataCacheService: Position de caméra mise en cache');
  }
  
  /// Invalider le cache des zones de danger
  void invalidateDangerZonesCache() {
    _cachedDangerZones = null;
    _dangerZonesCacheTime = null;
    log('MapDataCacheService: Cache des zones de danger invalidé');
  }
  
  /// Invalider le cache des zones de sécurité
  void invalidateSafeZonesCache() {
    _cachedSafeZones = null;
    _safeZonesCacheTime = null;
    log('MapDataCacheService: Cache des zones de sécurité invalidé');
  }
  
  /// Invalider le cache de position
  void invalidatePositionCache() {
    _cachedPosition = null;
    _positionCacheTime = null;
    log('MapDataCacheService: Cache de position invalidé');
  }
  
  /// Invalider tout le cache
  void invalidateAllCache() {
    invalidateDangerZonesCache();
    invalidateSafeZonesCache();
    invalidatePositionCache();
    _cachedCameraPosition = null;
    log('MapDataCacheService: Tout le cache invalidé');
  }
  
  /// Forcer le rechargement au prochain accès
  void forceReload() {
    invalidateAllCache();
    _isInitialized = false;
    _isInitializing = false;
    log('MapDataCacheService: Rechargement forcé');
  }
  
  /// Invalider tout le cache
  void invalidateCache() {
    invalidatePositionCache();
    invalidateDangerZonesCache();
    invalidateSafeZonesCache();
    _cachedCameraPosition = null;
    _isInitialized = false;
    _isInitializing = false;
    log('MapDataCacheService: Tout le cache invalidé via invalidateCache');
  }

  /// Obtenir un résumé du cache
  Map<String, dynamic> getCacheSummary() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'dangerZonesCount': _cachedDangerZones?.length ?? 0,
      'safeZonesCount': _cachedSafeZones?.length ?? 0,
      'hasPosition': _cachedPosition != null,
      'hasCameraPosition': _cachedCameraPosition != null,
      'dangerZonesCacheValid': hasValidDangerZonesCache,
      'safeZonesCacheValid': hasValidSafeZonesCache,
      'positionCacheValid': hasValidPositionCache,
    };
  }
}