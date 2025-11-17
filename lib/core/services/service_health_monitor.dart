import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de monitoring de santé des services de surveillance
/// Surveille l'état des services et alerte en cas de dysfonctionnement
class ServiceHealthMonitor {
  static final ServiceHealthMonitor _instance =
      ServiceHealthMonitor._internal();
  factory ServiceHealthMonitor() => _instance;
  ServiceHealthMonitor._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Timer? _healthCheckTimer;
  bool _isInitialized = false;

  // Configuration du monitoring
  static const Duration _healthCheckInterval = Duration(minutes: 10);
  static const Duration _serviceTimeoutThreshold = Duration(minutes: 15);
  static const int _healthAlertNotificationId = 9002;
  static const String _healthChannelId = 'service_health';
  static const String _healthChannelName = 'Santé des services';
  static const String _healthChannelDescription =
      'Alertes en cas de dysfonctionnement des services';

  // Clés de préférences
  static const String _keyHealthMonitoringEnabled = 'health_monitoring_enabled';
  static const String _keyLastHealthCheck = 'last_health_check';
  static const String _keyServiceFailures = 'service_failures';

  // État du monitoring
  final Map<String, DateTime> _lastServiceActivity = {};
  final Map<String, int> _serviceFailureCount = {};
  final List<ServiceHealthIssue> _currentIssues = [];

  /// Initialiser le service de monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeNotifications();
      await _loadSettings();
      _startHealthMonitoring();

      _isInitialized = true;
      log('ServiceHealthMonitor: Initialized successfully');
    } catch (e) {
      log('ServiceHealthMonitor: Initialization error: $e');
    }
  }

  /// Initialiser les notifications
  Future<void> _initializeNotifications() async {
    // Créer le canal de notification Android pour les alertes de santé
    const androidChannel = AndroidNotificationChannel(
      _healthChannelId,
      _healthChannelName,
      description: _healthChannelDescription,
      importance:
          Importance.high, // Importance élevée pour les alertes de santé
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Charger les paramètres
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Charger les compteurs d'échecs
    final failuresJson = prefs.getString(_keyServiceFailures);
    if (failuresJson != null) {
      // Ici on pourrait désérialiser un JSON, pour l'instant on utilise des clés simples
      _serviceFailureCount['geolocation'] =
          prefs.getInt('failures_geolocation') ?? 0;
      _serviceFailureCount['geofencing'] =
          prefs.getInt('failures_geofencing') ?? 0;
      _serviceFailureCount['background_location'] =
          prefs.getInt('failures_background_location') ?? 0;
    }
  }

  /// Démarrer le monitoring de santé
  void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      _healthCheckInterval,
      (_) => _performHealthCheck(),
    );
  }

  /// Enregistrer l'activité d'un service
  void recordServiceActivity(String serviceName) {
    _lastServiceActivity[serviceName] = DateTime.now();

    // Réinitialiser le compteur d'échecs si le service fonctionne
    if (_serviceFailureCount[serviceName] != null &&
        _serviceFailureCount[serviceName]! > 0) {
      _serviceFailureCount[serviceName] = 0;
      _saveFailureCount(serviceName, 0);
      log('ServiceHealthMonitor: Service $serviceName recovered');
    }
  }

  /// Enregistrer un échec de service
  void recordServiceFailure(String serviceName, String error) {
    _serviceFailureCount[serviceName] =
        (_serviceFailureCount[serviceName] ?? 0) + 1;
    _saveFailureCount(serviceName, _serviceFailureCount[serviceName]!);

    log(
      'ServiceHealthMonitor: Service $serviceName failed: $error (failures: ${_serviceFailureCount[serviceName]})',
    );

    // Déclencher une vérification immédiate
    _performHealthCheck();
  }

  /// Effectuer une vérification de santé
  Future<void> _performHealthCheck() async {
    if (!_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyHealthMonitoringEnabled) ?? true;

    if (!enabled) return;

    _currentIssues.clear();
    final now = DateTime.now();

    // Vérifier chaque service
    for (final serviceName in [
      'geolocation',
      'geofencing',
      'background_location',
    ]) {
      final lastActivity = _lastServiceActivity[serviceName];
      final failureCount = _serviceFailureCount[serviceName] ?? 0;

      // Vérifier si le service est inactif depuis trop longtemps
      if (lastActivity != null) {
        final timeSinceActivity = now.difference(lastActivity);
        if (timeSinceActivity > _serviceTimeoutThreshold) {
          _currentIssues.add(
            ServiceHealthIssue(
              serviceName: serviceName,
              type: HealthIssueType.timeout,
              description:
                  'Service inactif depuis ${_formatDuration(timeSinceActivity)}',
              severity: HealthIssueSeverity.warning,
              timestamp: now,
            ),
          );
        }
      }

      // Vérifier les échecs répétés
      if (failureCount >= 3) {
        _currentIssues.add(
          ServiceHealthIssue(
            serviceName: serviceName,
            type: HealthIssueType.repeatedFailures,
            description: '$failureCount échecs consécutifs',
            severity: failureCount >= 5
                ? HealthIssueSeverity.critical
                : HealthIssueSeverity.warning,
            timestamp: now,
          ),
        );
      }
    }

    // Envoyer des alertes si nécessaire
    if (_currentIssues.isNotEmpty) {
      await _sendHealthAlert();
    }

    // Sauvegarder l'heure de la dernière vérification
    await prefs.setString(_keyLastHealthCheck, now.toIso8601String());
  }

  /// Envoyer une alerte de santé
  Future<void> _sendHealthAlert() async {
    final criticalIssues = _currentIssues
        .where((i) => i.severity == HealthIssueSeverity.critical)
        .toList();
    final warningIssues = _currentIssues
        .where((i) => i.severity == HealthIssueSeverity.warning)
        .toList();

    String title;
    String body;
    Color notificationColor;

    if (criticalIssues.isNotEmpty) {
      title = '⚠️ Problème critique détecté';
      body =
          'Services affectés: ${criticalIssues.map((i) => _getServiceDisplayName(i.serviceName)).join(', ')}';
      notificationColor = Colors.red;
    } else {
      title = '⚠️ Avertissement de service';
      body =
          'Services affectés: ${warningIssues.map((i) => _getServiceDisplayName(i.serviceName)).join(', ')}';
      notificationColor = Colors.orange;
    }

    final androidDetails = AndroidNotificationDetails(
      _healthChannelId,
      _healthChannelName,
      channelDescription: _healthChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      color: notificationColor,
      styleInformation: BigTextStyleInformation(
        _buildDetailedHealthReport(),
        contentTitle: title,
        summaryText: 'AlertContact - Monitoring',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'service_health',
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        _healthAlertNotificationId,
        title,
        body,
        platformDetails,
      );

      log('ServiceHealthMonitor: Health alert sent');
    } catch (e) {
      log('ServiceHealthMonitor: Error sending health alert: $e');
    }
  }

  /// Construire un rapport détaillé de santé
  String _buildDetailedHealthReport() {
    final lines = <String>[];

    for (final issue in _currentIssues) {
      final icon = issue.severity == HealthIssueSeverity.critical ? '🔴' : '🟡';
      lines.add(
        '$icon ${_getServiceDisplayName(issue.serviceName)}: ${issue.description}',
      );
    }

    lines.add('');
    lines.add(
      'Vérifiez les paramètres de l\'application pour plus de détails.',
    );

    return lines.join('\n');
  }

  /// Obtenir le nom d'affichage d'un service
  String _getServiceDisplayName(String serviceName) {
    switch (serviceName) {
      case 'geolocation':
        return 'Géolocalisation';
      case 'background_location':
        return 'Localisation continue';
      default:
        return serviceName;
    }
  }

  /// Formater une durée
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  /// Sauvegarder le compteur d'échecs
  Future<void> _saveFailureCount(String serviceName, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failures_$serviceName', count);
  }

  /// Activer/désactiver le monitoring de santé
  Future<void> setHealthMonitoringEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHealthMonitoringEnabled, enabled);

    if (enabled) {
      _startHealthMonitoring();
    } else {
      _healthCheckTimer?.cancel();
    }

    log(
      'ServiceHealthMonitor: Health monitoring ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Vérifier si le monitoring de santé est activé
  Future<bool> isHealthMonitoringEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHealthMonitoringEnabled) ?? true;
  }

  /// Obtenir les problèmes actuels
  List<ServiceHealthIssue> get currentIssues =>
      List.unmodifiable(_currentIssues);

  /// Obtenir les statistiques de santé
  Map<String, dynamic> getHealthStatistics() {
    return {
      'current_issues': _currentIssues.length,
      'service_failures': Map.from(_serviceFailureCount),
      'last_activity': _lastServiceActivity.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
    };
  }

  /// Réinitialiser les compteurs d'échecs
  Future<void> resetFailureCounters() async {
    _serviceFailureCount.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('failures_geolocation');
    await prefs.remove('failures_geofencing');
    await prefs.remove('failures_background_location');

    log('ServiceHealthMonitor: Failure counters reset');
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();
    _isInitialized = false;
    log('ServiceHealthMonitor: Disposed');
  }
}

/// Problème de santé d'un service
class ServiceHealthIssue {
  final String serviceName;
  final HealthIssueType type;
  final String description;
  final HealthIssueSeverity severity;
  final DateTime timestamp;

  ServiceHealthIssue({
    required this.serviceName,
    required this.type,
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}

/// Type de problème de santé
enum HealthIssueType {
  timeout,
  repeatedFailures,
  permissionDenied,
  configurationError,
}

/// Sévérité du problème de santé
enum HealthIssueSeverity { warning, critical }
