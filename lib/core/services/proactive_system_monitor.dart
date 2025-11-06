// lib/core/services/proactive_system_monitor.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de monitoring proactif pour détecter les problèmes avant qu'ils
/// n'affectent les notifications critiques de sécurité
class ProactiveSystemMonitor {
  static final ProactiveSystemMonitor _instance = ProactiveSystemMonitor._internal();
  factory ProactiveSystemMonitor() => _instance;
  ProactiveSystemMonitor._internal();

  // Services de monitoring
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  
  // Timers de surveillance
  Timer? _systemHealthTimer;
  Timer? _connectivityTimer;
  Timer? _permissionsTimer;
  Timer? _batteryTimer;
  Timer? _backendHealthTimer;
  
  // État du système
  SystemHealthStatus _currentStatus = SystemHealthStatus.unknown;
  final List<SystemAlert> _activeAlerts = [];
  final Map<String, DateTime> _lastChecks = {};
  
  // Configuration
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  static const Duration _connectivityCheckInterval = Duration(seconds: 30);
  static const Duration _permissionsCheckInterval = Duration(minutes: 5);
  static const Duration _batteryCheckInterval = Duration(minutes: 1);
  static const Duration _backendCheckInterval = Duration(minutes: 1);
  
  // Seuils critiques
  static const int _criticalBatteryLevel = 15;
  static const int _warningBatteryLevel = 25;
  static const Duration _maxBackendResponseTime = Duration(seconds: 5);
  static const int _maxConsecutiveFailures = 3;
  
  // Compteurs d'échecs
  final Map<String, int> _failureCounters = {};
  
  bool _isInitialized = false;
  
  /// Initialiser le monitoring proactif
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadPreviousState();
      _startAllMonitoring();
      
      _isInitialized = true;
      log('ProactiveSystemMonitor: Initialized successfully');
      
      // Vérification initiale complète
      await _performCompleteHealthCheck();
    } catch (e) {
      log('ProactiveSystemMonitor: Initialization error: $e');
      rethrow;
    }
  }

  /// Démarrer tous les types de monitoring
  void _startAllMonitoring() {
    _startSystemHealthMonitoring();
    _startConnectivityMonitoring();
    _startPermissionsMonitoring();
    _startBatteryMonitoring();
    _startBackendHealthMonitoring();
  }

  /// Monitoring de la santé générale du système
  void _startSystemHealthMonitoring() {
    _systemHealthTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performCompleteHealthCheck();
    });
  }

  /// Monitoring de la connectivité réseau
  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(_connectivityCheckInterval, (_) {
      _checkConnectivity();
    });
    
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _handleConnectivityChange(results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
  }

  /// Monitoring des permissions critiques
  void _startPermissionsMonitoring() {
    _permissionsTimer = Timer.periodic(_permissionsCheckInterval, (_) {
      _checkCriticalPermissions();
    });
  }

  /// Monitoring de la batterie
  void _startBatteryMonitoring() {
    _batteryTimer = Timer.periodic(_batteryCheckInterval, (_) {
      _checkBatteryStatus();
    });
    
    // Écouter les changements d'état de la batterie
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _handleBatteryStateChange(state);
    });
  }

  /// Monitoring de la santé du backend
  void _startBackendHealthMonitoring() {
    _backendHealthTimer = Timer.periodic(_backendCheckInterval, (_) {
      _checkBackendHealth();
    });
  }

  /// Vérification complète de la santé du système
  Future<void> _performCompleteHealthCheck() async {
    log('🔍 Démarrage vérification complète du système');
    
    final checks = await Future.wait([
      _checkConnectivity(),
      _checkCriticalPermissions(),
      _checkBatteryStatus(),
      _checkBackendHealth(),
    ]);

    final hasErrors = checks.any((result) => !result);
    
    if (hasErrors) {
      _currentStatus = SystemHealthStatus.degraded;
      await _triggerSystemAlert(
        SystemAlertType.systemDegraded,
        'Système dégradé',
        'Plusieurs composants critiques présentent des problèmes',
        AlertSeverity.warning,
      );
    } else {
      _currentStatus = SystemHealthStatus.healthy;
      _clearAlertsOfType(SystemAlertType.systemDegraded);
    }

    _lastChecks['complete_health'] = DateTime.now();
    await _saveCurrentState();
  }

  /// Vérifier la connectivité réseau
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      if (result.contains(ConnectivityResult.none)) {
        await _triggerSystemAlert(
          SystemAlertType.noConnectivity,
          'Pas de connexion réseau',
          'Les alertes de sécurité ne peuvent pas être envoyées sans connexion',
          AlertSeverity.critical,
        );
        _incrementFailureCounter('connectivity');
        return false;
      } else {
        _clearAlertsOfType(SystemAlertType.noConnectivity);
        _resetFailureCounter('connectivity');
        
        // Test de connectivité réelle
        return await _testInternetConnectivity();
      }
    } catch (e) {
      log('❌ Erreur vérification connectivité: $e');
      _incrementFailureCounter('connectivity');
      return false;
    }
  }

  /// Tester la connectivité Internet réelle
  Future<bool> _testInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _clearAlertsOfType(SystemAlertType.internetConnectivity);
        return true;
      } else {
        await _triggerSystemAlert(
          SystemAlertType.internetConnectivity,
          'Connectivité Internet limitée',
          'Connexion réseau détectée mais accès Internet impossible',
          AlertSeverity.warning,
        );
        return false;
      }
    } catch (e) {
      await _triggerSystemAlert(
        SystemAlertType.internetConnectivity,
        'Test de connectivité échoué',
        'Impossible de vérifier l\'accès Internet: $e',
        AlertSeverity.warning,
      );
      return false;
    }
  }

  /// Vérifier les permissions critiques
  Future<bool> _checkCriticalPermissions() async {
    final criticalPermissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.notification,
    ];

    bool allGranted = true;
    final deniedPermissions = <Permission>[];

    for (final permission in criticalPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        deniedPermissions.add(permission);
        allGranted = false;
      }
    }

    if (!allGranted) {
      await _triggerSystemAlert(
        SystemAlertType.permissionsDenied,
        'Permissions critiques manquantes',
        'Permissions refusées: ${deniedPermissions.map((p) => p.toString()).join(', ')}',
        AlertSeverity.critical,
      );
      _incrementFailureCounter('permissions');
    } else {
      _clearAlertsOfType(SystemAlertType.permissionsDenied);
      _resetFailureCounter('permissions');
    }

    return allGranted;
  }

  /// Vérifier l'état de la batterie
  Future<bool> _checkBatteryStatus() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      if (batteryLevel <= _criticalBatteryLevel) {
        await _triggerSystemAlert(
          SystemAlertType.criticalBattery,
          'Batterie critique',
          'Niveau de batterie très faible ($batteryLevel%). '
              'Les notifications pourraient être interrompues.',
          AlertSeverity.critical,
        );
        return false;
      } else if (batteryLevel <= _warningBatteryLevel) {
        await _triggerSystemAlert(
          SystemAlertType.lowBattery,
          'Batterie faible',
          'Niveau de batterie bas ($batteryLevel%). '
              'Pensez à recharger votre appareil.',
          AlertSeverity.warning,
        );
      } else {
        _clearAlertsOfType(SystemAlertType.criticalBattery);
        _clearAlertsOfType(SystemAlertType.lowBattery);
      }

      // Vérifier le mode d'économie d'énergie
      if (batteryState == BatteryState.unknown) {
        await _triggerSystemAlert(
          SystemAlertType.batteryOptimization,
          'État batterie inconnu',
          'Impossible de déterminer l\'état de la batterie. '
              'Vérifiez les paramètres d\'optimisation.',
          AlertSeverity.warning,
        );
      }

      return true;
    } catch (e) {
      log('❌ Erreur vérification batterie: $e');
      return false;
    }
  }

  /// Vérifier la santé du backend
  Future<bool> _checkBackendHealth() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simuler un ping au backend (à adapter selon votre API)
      final response = await _pingBackend();
      
      stopwatch.stop();
      final responseTime = stopwatch.elapsed;

      if (!response.success) {
        await _triggerSystemAlert(
          SystemAlertType.backendDown,
          'Serveur indisponible',
          'Le serveur de sécurité ne répond pas. '
              'Les alertes pourraient ne pas fonctionner.',
          AlertSeverity.critical,
        );
        _incrementFailureCounter('backend');
        return false;
      } else if (responseTime > _maxBackendResponseTime) {
        await _triggerSystemAlert(
          SystemAlertType.backendSlow,
          'Serveur lent',
          'Le serveur répond lentement (${responseTime.inSeconds}s). '
              'Les alertes pourraient être retardées.',
          AlertSeverity.warning,
        );
      } else {
        _clearAlertsOfType(SystemAlertType.backendDown);
        _clearAlertsOfType(SystemAlertType.backendSlow);
        _resetFailureCounter('backend');
      }

      return true;
    } catch (e) {
      log('❌ Erreur vérification backend: $e');
      _incrementFailureCounter('backend');
      return false;
    }
  }

  /// Ping du backend (à adapter selon votre API)
  Future<BackendPingResponse> _pingBackend() async {
    try {
      // TODO: Remplacer par votre endpoint de health check
      // final response = await http.get(Uri.parse('$baseUrl/health'));
      // return BackendPingResponse(success: response.statusCode == 200);
      
      // Simulation pour l'exemple
      await Future.delayed(const Duration(milliseconds: 500));
      return BackendPingResponse(success: true);
    } catch (e) {
      return BackendPingResponse(success: false, error: e.toString());
    }
  }

  /// Gérer les changements de connectivité
  void _handleConnectivityChange(ConnectivityResult result) {
    log('📶 Changement de connectivité: $result');
    
    if (result == ConnectivityResult.none) {
      _triggerSystemAlert(
        SystemAlertType.connectivityLost,
        'Connexion perdue',
        'La connexion réseau a été perdue. '
            'Les alertes de sécurité ne peuvent plus être envoyées.',
        AlertSeverity.critical,
      );
    } else {
      _clearAlertsOfType(SystemAlertType.connectivityLost);
      log('✅ Connexion rétablie: $result');
    }
  }

  /// Gérer les changements d'état de la batterie
  void _handleBatteryStateChange(BatteryState state) {
    log('🔋 Changement état batterie: $state');
    
    if (state == BatteryState.charging) {
      _clearAlertsOfType(SystemAlertType.criticalBattery);
      _clearAlertsOfType(SystemAlertType.lowBattery);
    }
  }

  /// Déclencher une alerte système
  Future<void> _triggerSystemAlert(
    SystemAlertType type,
    String title,
    String message,
    AlertSeverity severity,
  ) async {
    // Éviter les doublons
    if (_activeAlerts.any((alert) => alert.type == type)) {
      return;
    }

    final alert = SystemAlert(
      type: type,
      title: title,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    );

    _activeAlerts.add(alert);
    
    log('🚨 Alerte système: $title - $message');
    
    // TODO: Intégrer avec CriticalNotificationRedundancyService
    
    await _saveCurrentState();
  }

  /// Effacer les alertes d'un type donné
  void _clearAlertsOfType(SystemAlertType type) {
    _activeAlerts.removeWhere((alert) => alert.type == type);
  }

  /// Incrémenter le compteur d'échecs
  void _incrementFailureCounter(String service) {
    _failureCounters[service] = (_failureCounters[service] ?? 0) + 1;
    
    if (_failureCounters[service]! >= _maxConsecutiveFailures) {
      _triggerSystemAlert(
        SystemAlertType.repeatedFailures,
        'Échecs répétés',
        'Le service $service a échoué ${_failureCounters[service]} fois consécutives',
        AlertSeverity.critical,
      );
    }
  }

  /// Réinitialiser le compteur d'échecs
  void _resetFailureCounter(String service) {
    _failureCounters[service] = 0;
  }

  /// Charger l'état précédent
  Future<void> _loadPreviousState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // TODO: Charger l'état précédent depuis SharedPreferences
    } catch (e) {
      log('❌ Erreur chargement état: $e');
    }
  }

  /// Sauvegarder l'état actuel
  Future<void> _saveCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // TODO: Sauvegarder l'état actuel dans SharedPreferences
    } catch (e) {
      log('❌ Erreur sauvegarde état: $e');
    }
  }

  /// Obtenir le statut actuel du système
  SystemHealthStatus get currentStatus => _currentStatus;

  /// Obtenir les alertes actives
  List<SystemAlert> get activeAlerts => List.unmodifiable(_activeAlerts);

  /// Obtenir les statistiques de monitoring
  Map<String, dynamic> getStatistics() {
    return {
      'status': _currentStatus.toString(),
      'active_alerts': _activeAlerts.length,
      'failure_counters': Map.from(_failureCounters),
      'last_checks': _lastChecks.map((k, v) => MapEntry(k, v.toIso8601String())),
      'is_initialized': _isInitialized,
    };
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _systemHealthTimer?.cancel();
    _connectivityTimer?.cancel();
    _permissionsTimer?.cancel();
    _batteryTimer?.cancel();
    _backendHealthTimer?.cancel();
    
    _isInitialized = false;
    log('ProactiveSystemMonitor: Disposed');
  }
}

/// Statut de santé du système
enum SystemHealthStatus {
  unknown,
  healthy,
  degraded,
  critical,
}

/// Types d'alertes système
enum SystemAlertType {
  noConnectivity,
  internetConnectivity,
  connectivityLost,
  permissionsDenied,
  criticalBattery,
  lowBattery,
  batteryOptimization,
  backendDown,
  backendSlow,
  systemDegraded,
  repeatedFailures,
}

/// Sévérité des alertes
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Alerte système
class SystemAlert {
  final SystemAlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;

  SystemAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

/// Réponse du ping backend
class BackendPingResponse {
  final bool success;
  final String? error;

  BackendPingResponse({required this.success, this.error});
}