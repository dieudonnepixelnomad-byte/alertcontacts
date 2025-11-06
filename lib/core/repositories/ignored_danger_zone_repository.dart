import 'dart:developer';
import '../models/ignored_danger_zone.dart';
import '../services/api_ignored_danger_zones_service.dart';
import '../services/prefs_service.dart';
import '../errors/auth_exceptions.dart';

class IgnoredDangerZoneRepository {
  final ApiIgnoredDangerZonesService _apiService;
  final PrefsService _prefs;

  IgnoredDangerZoneRepository({
    required ApiIgnoredDangerZonesService apiService,
    required PrefsService prefs,
  }) : _apiService = apiService,
       _prefs = prefs;

  /// Initialiser le repository avec le token Bearer
  Future<void> initialize() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      _apiService.setBearerToken(token);
      log('IgnoredDangerZoneRepository: Bearer token initialized');
    } else {
      log('IgnoredDangerZoneRepository: No bearer token found');
    }
  }

  /// S'assurer que l'utilisateur est authentifié
  Future<void> _ensureAuthenticated() async {
    final token = await _prefs.getBearerToken();
    if (token == null) {
      throw const UnknownAuthException('Token manquant');
    }
    _apiService.setBearerToken(token);
  }

  /// Ignorer une zone de danger
  Future<IgnoredDangerZone> ignoreDangerZone({
    required int dangerZoneId,
    required String reason,
    DateTime? expiresAt,
  }) async {
    try {
      await _ensureAuthenticated();
      
      log('IgnoredDangerZoneRepository.ignoreDangerZone: Ignoring zone $dangerZoneId');
      final ignoredZone = await _apiService.ignoreDangerZone(
        dangerZoneId: dangerZoneId.toString(),
        reason: reason,
      );
      
      log('IgnoredDangerZoneRepository.ignoreDangerZone: Zone ignored successfully');
      return ignoredZone;
    } catch (e) {
      log('IgnoredDangerZoneRepository.ignoreDangerZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Réactiver les alertes pour une zone
  Future<void> reactivateDangerZone(int dangerZoneId) async {
    try {
      await _ensureAuthenticated();
      
      log('IgnoredDangerZoneRepository.reactivateDangerZone: Reactivating zone $dangerZoneId');
      await _apiService.reactivateDangerZone(dangerZoneId.toString());
      
      log('IgnoredDangerZoneRepository.reactivateDangerZone: Zone reactivated successfully');
    } catch (e) {
      log('IgnoredDangerZoneRepository.reactivateDangerZone: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Récupérer les zones ignorées par l'utilisateur
  Future<List<IgnoredDangerZone>> getIgnoredZones() async {
    try {
      await _ensureAuthenticated();
      
      log('IgnoredDangerZoneRepository.getIgnoredZones: Fetching ignored zones');
      final zones = await _apiService.getIgnoredDangerZones();
      
      log('IgnoredDangerZoneRepository.getIgnoredZones: Retrieved ${zones.length} ignored zones');
      return zones;
    } catch (e) {
      log('IgnoredDangerZoneRepository.getIgnoredZones: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Étendre la durée d'une zone ignorée
  Future<bool> extendIgnoredZone(int dangerZoneId) async {
    try {
      await _ensureAuthenticated();
      
      log('IgnoredDangerZoneRepository.extendIgnoredZone: Extending zone $dangerZoneId');
      await _apiService.extendIgnoredZone(dangerZoneId.toString());
      
      log('IgnoredDangerZoneRepository.extendIgnoredZone: Extension successful');
      return true;
    } catch (e) {
      log('IgnoredDangerZoneRepository.extendIgnoredZone: Error: $e');
      if (e is AuthException) rethrow;
      return false;
    }
  }

  /// Vérifier si une zone est ignorée
  Future<bool> isZoneIgnored(int dangerZoneId) async {
    try {
      await _ensureAuthenticated();
      
      log('IgnoredDangerZoneRepository.isZoneIgnored: Checking zone $dangerZoneId');
      final isIgnored = await _apiService.isZoneIgnored(dangerZoneId.toString());
      
      log('IgnoredDangerZoneRepository.isZoneIgnored: Zone is ${isIgnored ? 'ignored' : 'not ignored'}');
      return isIgnored;
    } catch (e) {
      log('IgnoredDangerZoneRepository.isZoneIgnored: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }
}