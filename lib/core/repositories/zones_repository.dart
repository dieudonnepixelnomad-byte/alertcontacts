import 'dart:developer';
import '../models/zone.dart';
import '../services/api_zones_service.dart';
import '../services/prefs_service.dart';
import '../services/zones_cache_service.dart';
import '../errors/auth_exceptions.dart';

class ZonesRepository {
  final ApiZonesService _apiService;
  final PrefsService _prefs;
  final ZonesCacheService _cacheService;

  ZonesRepository({
    required ApiZonesService apiService,
    required PrefsService prefs,
    ZonesCacheService? cacheService,
  }) : _apiService = apiService,
       _prefs = prefs,
       _cacheService = cacheService ?? ZonesCacheService();

  /// Initialiser le repository avec le token Bearer
  Future<void> initialize() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      _apiService.setBearerToken(token);
      log('ZonesRepository: Bearer token initialized');
    } else {
      log('ZonesRepository: No bearer token found');
    }
  }

  /// Récupérer toutes les zones de l'utilisateur
  Future<List<Zone>> getMyZones({bool forceRefresh = false}) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      // Vérifier le cache d'abord si on ne force pas le refresh
      if (!forceRefresh) {
        final cachedZones = _cacheService.getCachedUnifiedZones();
        if (cachedZones != null) {
          log('ZonesRepository.getMyZones: Returning ${cachedZones.length} cached zones');
          return cachedZones;
        }
      }
      
      log('ZonesRepository.getMyZones: Fetching zones from API');
      final zones = await _apiService.getMyZones();
      
      // Mettre en cache les zones récupérées
      _cacheService.cacheUnifiedZones(zones);
      
      log('ZonesRepository.getMyZones: Retrieved ${zones.length} zones from API');
      return zones;
    } catch (e) {
      log('ZonesRepository.getMyZones: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Mettre à jour une zone existante
  Future<Zone> updateZone(Zone zone, Map<String, dynamic> data) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('ZonesRepository.updateZone: Updating zone ${zone.id}');
      final updatedZone = await _apiService.updateZone(zone, data);
      
      // Invalider le cache des zones de sécurité (les zones unifiées sont basées sur les SafeZones)
      _cacheService.invalidateSafeZonesCache();
      
      log('ZonesRepository.updateZone: Zone updated successfully');
      return updatedZone;
    } catch (e) {
      log('ZonesRepository.updateZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Supprimer une zone
  Future<bool> deleteZone(Zone zone) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('ZonesRepository.deleteZone: Deleting zone ${zone.id}');
      await _apiService.deleteZone(zone);
      
      // Invalider le cache des zones de sécurité (les zones unifiées sont basées sur les SafeZones)
      _cacheService.invalidateSafeZonesCache();
      
      log('ZonesRepository.deleteZone: Zone deleted successfully');
      return true;
    } catch (e) {
      log('ZonesRepository.deleteZone: Error: $e');
      if (e is AuthException) rethrow;
      return false;
    }
  }

  /// S'assurer que l'utilisateur est authentifié
  Future<void> _ensureAuthenticated() async {
    final token = await _prefs.getBearerToken();
    if (token == null) {
      throw const InvalidCredentialsException();
    }
    _apiService.setBearerToken(token);
  }

  /// Invalider le cache des zones unifiées
  void invalidateCache() {
    _cacheService.invalidateSafeZonesCache();
    log('ZonesRepository: Unified zones cache invalidated');
  }

  /// Vérifier si le cache des zones unifiées est valide
  bool isCacheValid() {
    return _cacheService.isSafeZonesCacheValid();
  }

  /// Obtenir les statistiques du cache
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getCacheStats();
  }

  /// Nettoyer les ressources
  void dispose() {
    // Nettoyer les ressources si nécessaire
    log('ZonesRepository: Resources cleaned up');
  }
}
