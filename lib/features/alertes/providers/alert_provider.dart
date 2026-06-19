import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/community_alert.dart';
import '../../../core/services/api_alerts_service.dart';
import '../../../core/services/notification_manager.dart';
import '../../../core/services/unified_alert_service.dart';
import '../../../core/services/prefs_service.dart';
import '../services/alert_service.dart';
import '../services/alert_acknowledgment_service.dart';

enum AlertStatus { uninitialized, initializing, ready, loading, error }

class AlertProvider extends ChangeNotifier {
  final ApiAlertsService _apiAlertsService;
  final PrefsService _prefs;
  final AlertService _alertService = AlertService();
  final AlertAcknowledgmentService _acknowledgmentService =
      AlertAcknowledgmentService();

  AlertStatus _status = AlertStatus.uninitialized;
  String? _errorMessage;
  List<CommunityAlert> _alerts = [];
  final Set<String> _readIds = {};
  int _createdCount = 0;

  // IDs des alertes déjà vues — null = pas encore de premier fetch
  Set<String>? _seenAlertIds;

  // Cooldown par alerte — répétition toutes les 5 min, max 3 fois
  static const _repeatCooldown = Duration(minutes: 5);
  static const _maxRepeats = 3;
  final Map<String, DateTime> _lastAlertedAt = {};
  final Map<String, int> _alertRepeatCount = {};

  // Polling périodique — toutes les 2 minutes quand initialisé
  static const _pollInterval = Duration(minutes: 2);
  Timer? _fetchTimer;

  AlertProvider(this._apiAlertsService, this._prefs) {
    _alertService.addListener(_onAlertServiceChanged);
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      log('[AlertProvider] _initToken: token SET');
      _apiAlertsService.setBearerToken(token);
    } else {
      log('[AlertProvider] _initToken: AUCUN token — alerts/nearby nécessite auth');
    }
  }

  Future<void> _ensureToken() async {
    final token = await _prefs.getBearerToken();
    _apiAlertsService.setBearerToken(token);
    log('[AlertProvider] _ensureToken: token=${token != null ? "SET" : "NULL"}');
  }

  AlertStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _alertService.isInitialized;
  List<CommunityAlert> get alerts => _alerts;
  int get createdCount => _createdCount;
  int get unreadCount => _alerts.where((a) => !_readIds.contains(a.id)).length;

  void _onAlertServiceChanged() => notifyListeners();

  Future<void> initialize() async {
    if (_status != AlertStatus.uninitialized) return;
    log('[AlertProvider] initialize: début');
    try {
      _status = AlertStatus.initializing;
      notifyListeners();

      // BUG FIX #1 : NotificationManager doit être initialisé avant tout appel
      // à triggerCommunityAlert — sinon _isInitialized=false → return silencieux.
      final nmInit = await NotificationManager().initialize();
      log('[AlertProvider] initialize: NotificationManager init=$nmInit');

      await Future.wait([
        _alertService.initialize(),
        _acknowledgmentService.load(),
      ]);

      _status = AlertStatus.ready;
      notifyListeners();
      log('[AlertProvider] initialize: succès, démarrage polling périodique');

      // BUG FIX #2 : polling périodique — fetchNearbyAlerts n'était appelé
      // qu'une seule fois depuis AlertesPage.initState. Sans timer, zéro alerte.
      _startPeriodicFetch();
    } catch (e) {
      log('[AlertProvider] initialize: ERREUR $e');
      _status = AlertStatus.error;
      _errorMessage = 'Erreur d\'initialisation: $e';
      notifyListeners();
    }
  }

  void _startPeriodicFetch() {
    _fetchTimer?.cancel();
    _fetchTimer = Timer.periodic(_pollInterval, (_) {
      log('[AlertProvider] timer tick — fetchNearbyAlerts');
      fetchNearbyAlerts();
    });
    log('[AlertProvider] polling démarré (interval=${_pollInterval.inMinutes}min)');
  }

  Future<void> fetchNearbyAlerts() async {
    if (_status == AlertStatus.loading) {
      log('[AlertProvider] fetchNearbyAlerts: déjà en cours, skip');
      return;
    }
    log('[AlertProvider] fetchNearbyAlerts: début (seenIds=${_seenAlertIds?.length ?? "null"})');
    _status = AlertStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureToken();

      Position? pos;
      try {
        // Last known position is instant — no GPS cold-start timeout
        pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          log('[AlertProvider] position (lastKnown): ${pos.latitude},${pos.longitude} acc=${pos.accuracy}m');
        } else {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
          ).timeout(const Duration(seconds: 8));
          log('[AlertProvider] position (fresh): ${pos.latitude},${pos.longitude} acc=${pos.accuracy}m');
        }
      } catch (e) {
        log('[AlertProvider] position indisponible ($e) — skip fetch');
        _status = AlertStatus.ready;
        notifyListeners();
        return;
      }

      log('[AlertProvider] GET alerts/nearby lat=${pos.latitude} lng=${pos.longitude}');
      final freshAlerts = await _apiAlertsService.getNearbyAlerts(
        lat: pos.latitude, lng: pos.longitude,
      );
      log('[AlertProvider] backend retourné: ${freshAlerts.length} alertes');

      // BUG FIX #3 : sur le PREMIER fetch _seenAlertIds==null — on initialise
      // sans alerter (évite bruit sur alertes déjà existantes à l'ouverture).
      // Dès le DEUXIÈME fetch (2 min plus tard via timer), les alertes non
      // acquittées déclenchent voix + vibration.
      if (_seenAlertIds == null) {
        log('[AlertProvider] premier fetch — initialise seenIds sans alerter');
      } else {
        final now = DateTime.now();
        for (final alert in freshAlerts) {
          final id = alert.id;
          final type = alert.type.toString().split('.').last;
          final gravity = alert.gravity.toString().split('.').last;

          if (_acknowledgmentService.isAcknowledged(id)) {
            log('[AlertProvider] alerte $id acquittée — skip');
            continue;
          }

          final dist = _haversineMeters(
            pos.latitude, pos.longitude, alert.lat, alert.lng,
          ).round();

          final isNew = !_seenAlertIds!.contains(id);
          final lastAlerteAt = _lastAlertedAt[id];
          final repeatCount = _alertRepeatCount[id] ?? 0;
          final cooldownPassed = lastAlerteAt == null ||
              now.difference(lastAlerteAt) >= _repeatCooldown;

          log('[AlertProvider] alerte $id type=$type gravity=$gravity dist=${dist}m '
              'isNew=$isNew repeatCount=$repeatCount cooldownPassed=$cooldownPassed');

          if (isNew || (cooldownPassed && repeatCount < _maxRepeats)) {
            log('[AlertProvider] → DÉCLENCHE alerte vocale (repeat #${repeatCount + 1})');
            _lastAlertedAt[id] = now;
            _alertRepeatCount[id] = repeatCount + 1;
            NotificationManager().triggerCommunityAlert(
              type: type,
              gravity: gravity,
              distanceMeters: dist,
            );
          } else {
            log('[AlertProvider] → skip (cooldown non écoulé ou max atteint)');
          }
        }
      }

      _seenAlertIds = freshAlerts.map((a) => a.id).toSet();
      _alerts = freshAlerts;
      _status = AlertStatus.ready;
      log('[AlertProvider] fetchNearbyAlerts: OK ${_alerts.length} alertes, seenIds=${_seenAlertIds!.length}');
    } catch (e) {
      log('[AlertProvider] fetchNearbyAlerts ERROR: $e');
      _status = AlertStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<CommunityAlert> createAlert(Map<String, dynamic> payload) async {
    log('[AlertProvider] createAlert: payload=$payload');
    await _ensureToken();
    try {
      final alert = await _apiAlertsService.createAlert(payload);
      _alerts = [alert, ..._alerts];
      _createdCount++;
      notifyListeners();
      log('[AlertProvider] createAlert: succès id=${alert.id}');
      return alert;
    } catch (e) {
      log('[AlertProvider] createAlert ERROR: $e');
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

  Future<void> confirmAlert(String alertId) async {
    log('[AlertProvider] confirmAlert: $alertId');
    await _ensureToken();
    try {
      await _apiAlertsService.confirmAlert(alertId);
      _alerts = _alerts.map((a) => a.id == alertId
          ? a.copyWith(confirmations: a.confirmations + 1) : a).toList();
      notifyListeners();
    } catch (e) {
      log('[AlertProvider] confirmAlert ERROR: $e');
      rethrow;
    }
  }

  Future<void> denyAlert(String alertId) async {
    log('[AlertProvider] denyAlert: $alertId');
    await _ensureToken();
    try {
      await _apiAlertsService.denyAlert(alertId);
      _alerts = _alerts.map((a) => a.id == alertId
          ? a.copyWith(denials: a.denials + 1) : a).toList();
      notifyListeners();
    } catch (e) {
      log('[AlertProvider] denyAlert ERROR: $e');
      rethrow;
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    log('[AlertProvider] acknowledgeAlert: $alertId');
    await _acknowledgmentService.acknowledgeAlert(alertId);
    markRead(alertId);
    await UnifiedAlertService().stopAllAlerts();
    notifyListeners();
  }

  bool isAcknowledged(String alertId) =>
      _acknowledgmentService.isAcknowledged(alertId);

  Future<void> restart() async {
    _fetchTimer?.cancel();
    _fetchTimer = null;
    _status = AlertStatus.uninitialized;
    _errorMessage = null;
    notifyListeners();
    await initialize();
  }

  Map<String, dynamic> getStatistics() => _alertService.getStatistics();

  @override
  void dispose() {
    _fetchTimer?.cancel();
    _alertService.removeListener(_onAlertServiceChanged);
    _alertService.dispose();
    super.dispose();
  }
}
