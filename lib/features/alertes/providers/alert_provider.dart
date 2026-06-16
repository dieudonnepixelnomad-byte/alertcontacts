import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/community_alert.dart';
import '../../../core/services/api_alerts_service.dart';
import '../../../core/services/notification_manager.dart';
import '../../../core/services/prefs_service.dart';
import '../services/alert_service.dart';

enum AlertStatus { uninitialized, initializing, ready, loading, error }

class AlertProvider extends ChangeNotifier {
  final ApiAlertsService _apiAlertsService;
  final PrefsService _prefs;
  final AlertService _alertService = AlertService();

  AlertStatus _status = AlertStatus.uninitialized;
  String? _errorMessage;
  List<CommunityAlert> _alerts = [];
  final Set<String> _readIds = {};

  // IDs des alertes déjà vues — null = pas encore de premier fetch
  Set<String>? _seenAlertIds;
  // Dernière position connue pour calculer la distance des nouvelles alertes
  double? _lastLat;
  double? _lastLng;

  AlertProvider(this._apiAlertsService, this._prefs) {
    _alertService.addListener(_onAlertServiceChanged);
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      log('AlertProvider._initToken: token trouvé, setté sur ApiAlertsService');
      _apiAlertsService.setBearerToken(token);
    } else {
      log('AlertProvider._initToken: AUCUN token dans PrefsService');
    }
  }

  Future<void> _ensureToken() async {
    final token = await _prefs.getBearerToken();
    _apiAlertsService.setBearerToken(token);
    log('AlertProvider._ensureToken: token=${token != null ? "SET" : "NULL"}');
  }

  AlertStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _alertService.isInitialized;
  List<CommunityAlert> get alerts => _alerts;
  int get unreadCount => _alerts
      .where((a) => !_readIds.contains(a.id))
      .length;

  void _onAlertServiceChanged() => notifyListeners();

  Future<void> initialize() async {
    if (_status != AlertStatus.uninitialized) return;
    try {
      _status = AlertStatus.initializing;
      notifyListeners();
      await _alertService.initialize();
      _status = AlertStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = AlertStatus.error;
      _errorMessage = 'Erreur d\'initialisation: $e';
      notifyListeners();
    }
  }

  Future<void> fetchNearbyAlerts() async {
    if (_status == AlertStatus.loading) return;
    _status = AlertStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureToken();

      // Récupérer position actuelle pour filtrer par proximité
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 8));
        log('AlertProvider.fetchNearbyAlerts: position=${pos.latitude},${pos.longitude}');
      } catch (e) {
        log('AlertProvider.fetchNearbyAlerts: position indisponible ($e) — fallback 0,0');
        // Fallback 0,0 : le backend retournera des alertes proches de (0,0) mais
        // c'est mieux que de ne rien afficher. À terme utiliser dernière position connue.
        pos = Position(
          latitude: 0, longitude: 0, timestamp: DateTime.now(),
          accuracy: 0, altitude: 0, altitudeAccuracy: 0,
          heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
        );
      }

      final freshAlerts = await _apiAlertsService.getNearbyAlerts(lat: pos.latitude, lng: pos.longitude);

      // Détecter les nouvelles alertes — null = premier fetch, pas de notification
      if (_seenAlertIds != null) {
        for (final alert in freshAlerts) {
          if (!_seenAlertIds!.contains(alert.id)) {
            final dist = _haversineMeters(
              pos.latitude, pos.longitude,
              alert.lat, alert.lng,
            ).round();
            log('AlertProvider: nouvelle alerte communautaire id=${alert.id} type=${alert.type} gravity=${alert.gravity} dist=${dist}m');
            NotificationManager().triggerCommunityAlert(
              type: alert.type.toString().split('.').last,
              gravity: alert.gravity.toString().split('.').last,
              distanceMeters: dist,
            );
          }
        }
      }

      _seenAlertIds = freshAlerts.map((a) => a.id).toSet();
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _alerts = freshAlerts;
      _status = AlertStatus.ready;
      log('AlertProvider.fetchNearbyAlerts: ${_alerts.length} alertes chargées');
    } catch (e) {
      log('AlertProvider.fetchNearbyAlerts error: $e');
      _status = AlertStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<CommunityAlert> createAlert(Map<String, dynamic> payload) async {
    log('AlertProvider.createAlert: début | payload=$payload');
    await _ensureToken();
    try {
      final alert = await _apiAlertsService.createAlert(payload);
      _alerts = [alert, ..._alerts];
      notifyListeners();
      log('AlertProvider.createAlert: succès | id=${alert.id}');
      return alert;
    } catch (e) {
      log('AlertProvider.createAlert error: $e');
      rethrow;
    }
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lng2 - lng1) * math.pi / 180;
    final a = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void markRead(String alertId) {
    _readIds.add(alertId);
    notifyListeners();
  }

  void markAllRead() {
    _readIds.addAll(_alerts.map((a) => a.id));
    notifyListeners();
  }

  bool isRead(String alertId) => _readIds.contains(alertId);

  Future<void> restart() async {
    _status = AlertStatus.uninitialized;
    _errorMessage = null;
    notifyListeners();
    await initialize();
  }

  Map<String, dynamic> getStatistics() => _alertService.getStatistics();

  @override
  void dispose() {
    _alertService.removeListener(_onAlertServiceChanged);
    _alertService.dispose();
    super.dispose();
  }
}
