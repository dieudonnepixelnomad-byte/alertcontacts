import 'dart:developer';
import '../models/safe_zone.dart';
import '../services/api_safezone_service.dart';
import '../services/prefs_service.dart';
import '../services/zones_cache_service.dart';
import '../errors/auth_exceptions.dart';

class SafeZoneRepository {
  final ApiSafeZoneService _apiService;
  final PrefsService _prefs;
  final ZonesCacheService _cacheService;

  SafeZoneRepository({
    required ApiSafeZoneService apiService,
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
      log('SafeZoneRepository: Bearer token initialized');
    } else {
      log('SafeZoneRepository: No bearer token found');
    }
  }

  /// Créer une nouvelle zone de sécurité
  Future<SafeZone> createSafeZone(SafeZone zone) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('SafeZoneRepository.createSafeZone: Creating zone ${zone.name}');
      final createdZone = await _apiService.createSafeZone(zone);
      
      // Invalider le cache des zones de sécurité
      _cacheService.invalidateSafeZonesCache();
      
      log('SafeZoneRepository.createSafeZone: Zone created successfully: ${createdZone.id}');
      return createdZone;
    } catch (e) {
      log('SafeZoneRepository.createSafeZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Récupérer toutes les zones de sécurité de l'utilisateur
  Future<List<SafeZone>> getSafeZones({bool forceRefresh = false}) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      // Vérifier le cache d'abord si on ne force pas le refresh
      if (!forceRefresh) {
        final cachedZones = _cacheService.getCachedSafeZones();
        if (cachedZones != null) {
          log('SafeZoneRepository.getSafeZones: Returning ${cachedZones.length} cached zones');
          return cachedZones;
        }
      }
      
      log('SafeZoneRepository.getSafeZones: Fetching user safe zones from API');
      final zones = await _apiService.getSafeZones();
      
      // Mettre en cache les zones récupérées
      _cacheService.cacheSafeZones(zones);
      
      log('SafeZoneRepository.getSafeZones: Retrieved ${zones.length} zones from API');
      return zones;
    } catch (e) {
      log('SafeZoneRepository.getSafeZones: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Mettre à jour une zone de sécurité
  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('SafeZoneRepository.updateSafeZone: Updating zone ${zone.id}');
      final updatedZone = await _apiService.updateSafeZone(zone);
      
      // Invalider le cache des zones de sécurité
      _cacheService.invalidateSafeZonesCache();
      
      log('SafeZoneRepository.updateSafeZone: Zone updated successfully');
      return updatedZone;
    } catch (e) {
      log('SafeZoneRepository.updateSafeZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Supprimer une zone de sécurité
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      // S'assurer que le token est à jour
      await _ensureAuthenticated();
      
      log('SafeZoneRepository.deleteSafeZone: Deleting zone $zoneId');
      await _apiService.deleteSafeZone(zoneId);
      
      // Invalider le cache des zones de sécurité
      _cacheService.invalidateSafeZonesCache();
      
      log('SafeZoneRepository.deleteSafeZone: Zone deleted successfully');
    } catch (e) {
      log('SafeZoneRepository.deleteSafeZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
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

  /// Invalider le cache des zones de sécurité
  void invalidateCache() {
    _cacheService.invalidateSafeZonesCache();
    log('SafeZoneRepository: Safe zones cache invalidated');
  }

  /// Vérifier si le cache des zones de sécurité est valide
  bool isCacheValid() {
    return _cacheService.isSafeZonesCacheValid();
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