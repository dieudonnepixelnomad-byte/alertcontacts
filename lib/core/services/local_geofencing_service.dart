import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import '../models/location_point.dart';
import 'alert_event_store.dart';
import 'batch_sender_service.dart';
import 'unified_alert_service.dart';
import 'zones_cache_service.dart';

/// Géofencing local — complément offline au backend
///
/// Vérifie chaque point GPS reçu contre les zones en cache pour :
/// - DangerZone : alerte locale immédiate (TTS + vibration) + flush batch vers backend
/// - SafeZone : détection de transition entrée/sortie + flush batch vers backend
///
/// Le backend reste authoritative. Ce service réduit la latence d'alerte
/// et maintient la détection quand la connexion est temporairement coupée.
class LocalGeofencingService {
  static final LocalGeofencingService _instance =
      LocalGeofencingService._internal();
  factory LocalGeofencingService() => _instance;
  LocalGeofencingService._internal();

  final ZonesCacheService _zonesCache = ZonesCacheService();
  final BatchSenderService _batchSender = BatchSenderService();
  final UnifiedAlertService _alertService = UnifiedAlertService();

  // État des SafeZones : zoneId → true si l'utilisateur est à l'intérieur
  final Map<String, bool> _safeZoneState = {};

  // Cooldown local DangerZone (12h, miroir du cooldown backend)
  final Map<String, DateTime> _dangerZoneCooldowns = {};
  static const Duration _dangerZoneCooldownDuration = Duration(hours: 12);

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _alertService.initialize();
    _isInitialized = true;
    developer.log(
      'LocalGeofencingService initialized',
      name: 'LocalGeofencingService',
    );
  }

  /// Vérifier un point GPS contre toutes les zones en cache
  Future<void> checkLocation(LocationPoint point) async {
    if (!_isInitialized) return;
    await Future.wait([
      _checkDangerZones(point),
      _checkSafeZones(point),
    ]);
  }

  Future<void> _checkDangerZones(LocationPoint point) async {
    final zones = _zonesCache.getAllCachedDangerZones();
    if (zones.isEmpty) return;

    for (final zone in zones) {
      final distanceM = _haversineMeters(
        point.latitude,
        point.longitude,
        zone.center.lat,
        zone.center.lng,
      );

      if (distanceM > zone.radiusMeters) continue;
      if (_isDangerZoneInCooldown(zone.id)) continue;

      _dangerZoneCooldowns[zone.id] = DateTime.now();

      developer.log(
        'DangerZone détectée localement : ${zone.title} à ${distanceM.round()}m',
        name: 'LocalGeofencingService',
      );

      // Flush immédiat pour déclencher le traitement backend sans attendre le timer
      _batchSender.flushNow();

      // Alerte locale (TTS + vibration) — active en foreground
      await _alertService.triggerDangerZoneAlert(
        zoneName: zone.title,
        distanceMeters: distanceM.round(),
      );
    }
  }

  Future<void> _checkSafeZones(LocationPoint point) async {
    final zones = _zonesCache.getCachedSafeZones();
    if (zones == null || zones.isEmpty) return;

    for (final zone in zones) {
      final distanceM = _haversineMeters(
        point.latitude,
        point.longitude,
        zone.center.lat,
        zone.center.lng,
      );
      final isInside = distanceM <= zone.radiusMeters;
      final wasInside = _safeZoneState[zone.id];

      // Premier point observé : initialiser l'état sans déclencher d'événement
      if (wasInside == null) {
        _safeZoneState[zone.id] = isInside;
        continue;
      }

      if (isInside == wasInside) continue;

      _safeZoneState[zone.id] = isInside;
      final transition = isInside ? 'entrée' : 'sortie';

      developer.log(
        'SafeZone transition ($transition) : ${zone.name} à ${distanceM.round()}m',
        name: 'LocalGeofencingService',
      );

      if (isInside) {
        AlertEventStore().addZoneEntry(zoneName: zone.name, contactName: 'Vous');
      } else {
        AlertEventStore().addZoneExit(zoneName: zone.name, contactName: 'Vous');
      }

      // Flush immédiat pour que le backend reçoive ce point sans délai de 20s
      _batchSender.flushNow();
    }
  }

  bool _isDangerZoneInCooldown(String zoneId) {
    final last = _dangerZoneCooldowns[zoneId];
    if (last == null) return false;
    return DateTime.now().difference(last) < _dangerZoneCooldownDuration;
  }

  /// Formule de Haversine — distance en mètres
  double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double degrees) => degrees * math.pi / 180;

  /// Réinitialiser l'état des SafeZones (ex : après une mise à jour du cache)
  void resetSafeZoneState() {
    _safeZoneState.clear();
    developer.log('SafeZone state reset', name: 'LocalGeofencingService');
  }

  void dispose() {
    _safeZoneState.clear();
    _dangerZoneCooldowns.clear();
    _isInitialized = false;
  }
}
