import 'dart:developer';
import '../models/danger_zone.dart';
import '../services/api_dangerzone_service.dart';
import '../services/prefs_service.dart';
import '../services/zones_cache_service.dart';
import '../errors/auth_exceptions.dart';

class DangerZoneRepository {
  final ApiDangerZoneService _apiService;
  final PrefsService _prefs;
  final ZonesCacheService _cacheService;

  DangerZoneRepository({
    required ApiDangerZoneService apiService,
    required PrefsService prefs,
    ZonesCacheService? cacheService,
  })  : _apiService = apiService,
        _prefs = prefs,
        _cacheService = cacheService ?? ZonesCacheService();

  /// Initialiser le repository avec le token Bearer
  Future<void> initialize() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      _apiService.setBearerToken(token);
      log('DangerZoneRepository: Bearer token initialized');
    } else {
      log('DangerZoneRepository: No bearer token found');
    }
  }

  /// Récupérer les zones de danger dans un rayon donné
  Future<List<DangerZone>> getDangerZones({
    double? lat,
    double? lng,
    double? radiusKm,
    bool forceRefresh = false,
  }) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      // Si les paramètres de localisation sont fournis et qu'on ne force pas le refresh
      if (lat != null && lng != null && radiusKm != null && !forceRefresh) {
        // Vérifier le cache d'abord
        final cachedZones = await _cacheService.getCachedDangerZones(
          lat: lat,
          lng: lng,
          radiusKm: radiusKm,
        );
        
        if (cachedZones != null) {
          log('DangerZoneRepository.getDangerZones: Returning ${cachedZones.length} cached zones');
          return cachedZones;
        }
      }
      
      log('DangerZoneRepository.getDangerZones: Fetching danger zones from API');
      final zones = await _apiService.getDangerZones(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      
      // Mettre en cache si les paramètres de localisation sont fournis
      if (lat != null && lng != null && radiusKm != null) {
        _cacheService.cacheDangerZones(
          lat: lat,
          lng: lng,
          radiusKm: radiusKm,
          zones: zones,
        );
      }
      
      log('DangerZoneRepository.getDangerZones: Retrieved ${zones.length} zones from API');
      return zones;
    } catch (e) {
      log('DangerZoneRepository.getDangerZones: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Créer une nouvelle zone de danger
  Future<DangerZone> createDangerZone(DangerZone zone) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('DangerZoneRepository.createDangerZone: Creating zone ${zone.title}');
      final createdZone = await _apiService.createDangerZone(zone);
      
      // Invalider le cache pour la région de la nouvelle zone
      _cacheService.invalidateDangerZonesCache(
        lat: zone.center.lat,
        lng: zone.center.lng,
        radiusKm: zone.radiusMeters / 1000, // Convertir en km
      );
      
      log('DangerZoneRepository.createDangerZone: Zone created successfully: ${createdZone.id}');
      return createdZone;
    } catch (e) {
      log('DangerZoneRepository.createDangerZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Confirmer une zone de danger
  Future<DangerZone> confirmDangerZone(String zoneId) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('DangerZoneRepository.confirmDangerZone: Confirming zone $zoneId');
      final updatedZone = await _apiService.confirmDangerZone(zoneId);
      
      // Invalider le cache pour la région de la zone confirmée
      _cacheService.invalidateDangerZonesCache(
        lat: updatedZone.center.lat,
        lng: updatedZone.center.lng,
        radiusKm: updatedZone.radiusMeters / 1000, // Convertir en km
      );
      
      log('DangerZoneRepository.confirmDangerZone: Zone confirmed successfully');
      return updatedZone;
    } catch (e) {
      log('DangerZoneRepository.confirmDangerZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Signaler un abus pour une zone de danger
  Future<void> reportAbuse(String zoneId, String reason) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('DangerZoneRepository.reportAbuse: Reporting abuse for zone $zoneId');
      await _apiService.reportAbuse(zoneId, reason);
      
      log('DangerZoneRepository.reportAbuse: Abuse reported successfully');
    } catch (e) {
      log('DangerZoneRepository.reportAbuse: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Nettoyer les zones expirées (plus de 30 jours)
  Future<int> cleanupExpiredZones() async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('DangerZoneRepository.cleanupExpiredZones: Cleaning up expired zones');
      final deletedCount = await _apiService.cleanupExpiredZones();
      
      log('DangerZoneRepository.cleanupExpiredZones: Deleted $deletedCount expired zones');
      return deletedCount;
    } catch (e) {
      log('DangerZoneRepository.cleanupExpiredZones: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Vérifier si une zone est expirée
  bool isZoneExpired(DangerZone zone) {
    return _apiService.isZoneExpired(zone);
  }

  /// Filtrer les zones expirées d'une liste
  List<DangerZone> filterExpiredZones(List<DangerZone> zones) {
    return _apiService.filterExpiredZones(zones);
  }

  /// S'assurer que l'utilisateur est authentifié
  Future<void> _ensureAuthenticated() async {
    final token = await _prefs.getBearerToken();
    if (token == null) {
      throw const InvalidCredentialsException();
    }
    _apiService.setBearerToken(token);
  }

  /// Invalider tout le cache des zones de danger
  void invalidateCache() {
    _cacheService.invalidateAllCache();
    log('DangerZoneRepository: Cache invalidated');
  }

  /// Vérifier si le cache est valide pour une région
  bool isCacheValid({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    return _cacheService.isDangerZonesCacheValid(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }

  /// Obtenir les statistiques du cache
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getCacheStats();
  }

  /// Nettoyer les ressources
  void dispose() {
    _apiService.dispose();
  }
}