// lib/core/services/unified_critical_alert_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'critical_notification_redundancy_service.dart';
import 'proactive_system_monitor.dart';

/// Service unifié pour la gestion des alertes critiques de sécurité
/// Intègre tous les systèmes de redondance et de monitoring pour garantir
/// une fiabilité maximale des notifications de sécurité
class UnifiedCriticalAlertService {
  static final UnifiedCriticalAlertService _instance = 
      UnifiedCriticalAlertService._internal();
  factory UnifiedCriticalAlertService() => _instance;
  UnifiedCriticalAlertService._internal();

  // Services intégrés
  final CriticalNotificationRedundancyService _redundancyService = 
      CriticalNotificationRedundancyService();
  final ProactiveSystemMonitor _systemMonitor = ProactiveSystemMonitor();
  
  // État du service
  bool _isInitialized = false;
  bool _isEmergencyMode = false;
  Timer? _healthCheckTimer;
  Timer? _emergencyModeTimer;
  
  // Configuration critique
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _emergencyModeTimeout = Duration(minutes: 10);
  static const int _maxFailedAlerts = 3;
  static const Duration _alertAcknowledgmentTimeout = Duration(minutes: 2);
  
  // Métriques de fiabilité
  int _totalAlertsGenerated = 0;
  int _totalAlertsDelivered = 0;
  int _totalAlertsAcknowledged = 0;
  int _consecutiveFailures = 0;
  final List<AlertDeliveryAttempt> _recentAttempts = [];
  
  // Callbacks pour l'interface utilisateur
  Function(CriticalSystemEvent)? onCriticalSystemEvent;
  Function(AlertReliabilityReport)? onReliabilityReport;
  
  /// Initialiser le service unifié
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      log('🚀 Initialisation du service unifié d\'alertes critiques');
      
      // Initialiser les services sous-jacents
      await _redundancyService.initialize();
      await _systemMonitor.initialize();
      
      // Configurer les callbacks de monitoring
      _setupSystemMonitoringCallbacks();
      
      // Démarrer la surveillance de santé
      _startHealthMonitoring();
      
      // Charger les métriques précédentes
      await _loadMetrics();
      
      _isInitialized = true;
      log('✅ Service unifié d\'alertes critiques initialisé');
      
      // Générer un rapport initial
      await _generateReliabilityReport();
      
    } catch (e) {
      log('❌ Erreur initialisation service unifié: $e');
      rethrow;
    }
  }

  /// Envoyer une alerte critique avec redondance maximale
  Future<AlertDeliveryResult> sendCriticalAlert({
    required String alertId,
    required String title,
    required String message,
    required CriticalAlertType type,
    required AlertPriority priority,
    Map<String, dynamic>? metadata,
    Duration? acknowledgmentTimeout,
  }) async {
    if (!_isInitialized) {
      throw StateError('Service non initialisé');
    }

    _totalAlertsGenerated++;
    final attempt = AlertDeliveryAttempt(
      alertId: alertId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _recentAttempts.add(attempt);
    
    // Garder seulement les 100 dernières tentatives
    if (_recentAttempts.length > 100) {
      _recentAttempts.removeAt(0);
    }

    log('🚨 Envoi alerte critique: $alertId - $title');

    try {
      // Vérifier l'état du système avant l'envoi
      final systemStatus = _systemMonitor.currentStatus;
      if (systemStatus == SystemHealthStatus.critical && !_isEmergencyMode) {
        await _activateEmergencyMode();
      }

      // Convertir le type pour le service de redondance
      final redundancyType = _convertToCriticalNotificationType(type);
      
      // Envoyer via le service de redondance
      await _redundancyService.sendCriticalNotificationWithRedundancy(
        alertId: alertId,
        title: title,
        message: message,
        type: redundancyType,
        metadata: metadata,
      );

      // Démarrer le monitoring d'accusé de réception
      _startAcknowledgmentMonitoring(
        attempt, 
        acknowledgmentTimeout ?? _alertAcknowledgmentTimeout
      );

      attempt.deliveryStatus = AlertDeliveryStatus.sent;
      _totalAlertsDelivered++;
      _consecutiveFailures = 0;

      log('✅ Alerte critique envoyée: $alertId');
      
      return AlertDeliveryResult(
        success: true,
        alertId: alertId,
        deliveryTime: DateTime.now().difference(attempt.startTime),
        channels: ['redundancy_service'],
      );

    } catch (e) {
      log('❌ Échec envoi alerte critique: $e');
      
      attempt.deliveryStatus = AlertDeliveryStatus.failed;
      attempt.errorMessage = e.toString();
      _consecutiveFailures++;

      // Déclencher le mode d'urgence si trop d'échecs
      if (_consecutiveFailures >= _maxFailedAlerts) {
        await _activateEmergencyMode();
      }

      // Tenter un envoi de secours
      await _attemptEmergencyFallback(attempt);

      return AlertDeliveryResult(
        success: false,
        alertId: alertId,
        error: e.toString(),
        deliveryTime: DateTime.now().difference(attempt.startTime),
      );
    }
  }

  /// Accuser réception d'une alerte
  Future<void> acknowledgeAlert(String alertId) async {
    log('✅ Accusé de réception alerte: $alertId');
    
    // Marquer dans le service de redondance
    await _redundancyService.acknowledgeAlert(alertId);
    
    // Mettre à jour les métriques
    final attempt = _recentAttempts
        .where((a) => a.alertId == alertId)
        .firstOrNull;
    
    if (attempt != null) {
      attempt.acknowledgedAt = DateTime.now();
      attempt.deliveryStatus = AlertDeliveryStatus.acknowledged;
      _totalAlertsAcknowledged++;
    }

    // Générer un rapport de fiabilité mis à jour
    await _generateReliabilityReport();
  }

  /// Activer le mode d'urgence
  Future<void> _activateEmergencyMode() async {
    if (_isEmergencyMode) return;

    _isEmergencyMode = true;
    log('🚨 ACTIVATION MODE D\'URGENCE');

    // Notifier l'interface utilisateur
    onCriticalSystemEvent?.call(CriticalSystemEvent(
      type: CriticalSystemEventType.emergencyModeActivated,
      message: 'Mode d\'urgence activé - Système de sécurité dégradé',
      timestamp: DateTime.now(),
      severity: EventSeverity.critical,
    ));

    // Programmer la désactivation automatique
    _emergencyModeTimer?.cancel();
    _emergencyModeTimer = Timer(_emergencyModeTimeout, () {
      _deactivateEmergencyMode();
    });

    // Envoyer une alerte système critique
    await _sendSystemCriticalAlert(
      'Mode d\'urgence activé',
      'Le système de sécurité fonctionne en mode dégradé. '
      'Vérifiez votre connexion et les paramètres de l\'application.',
    );
  }

  /// Désactiver le mode d'urgence
  void _deactivateEmergencyMode() {
    if (!_isEmergencyMode) return;

    _isEmergencyMode = false;
    _emergencyModeTimer?.cancel();
    
    log('✅ Désactivation mode d\'urgence');

    onCriticalSystemEvent?.call(CriticalSystemEvent(
      type: CriticalSystemEventType.emergencyModeDeactivated,
      message: 'Mode d\'urgence désactivé - Système de sécurité rétabli',
      timestamp: DateTime.now(),
      severity: EventSeverity.info,
    ));
  }

  /// Tentative de secours en cas d'échec
  Future<void> _attemptEmergencyFallback(AlertDeliveryAttempt attempt) async {
    log('🆘 Tentative de secours pour: ${attempt.alertId}');

    try {
      // TODO: Implémenter des mécanismes de secours
      // - SMS de secours
      // - Notification système native
      // - Sauvegarde locale pour retry ultérieur
      
      // Pour l'instant, sauvegarder pour retry
      await _saveFailedAlertForRetry(attempt);
      
    } catch (e) {
      log('❌ Échec tentative de secours: $e');
    }
  }

  /// Sauvegarder une alerte échouée pour retry
  Future<void> _saveFailedAlertForRetry(AlertDeliveryAttempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedAlerts = prefs.getStringList('failed_alerts') ?? [];
      
      failedAlerts.add(attempt.toJson());
      await prefs.setStringList('failed_alerts', failedAlerts);
      
      log('💾 Alerte sauvegardée pour retry: ${attempt.alertId}');
    } catch (e) {
      log('❌ Erreur sauvegarde alerte échouée: $e');
    }
  }

  /// Envoyer une alerte système critique
  Future<void> _sendSystemCriticalAlert(String title, String message) async {
    try {
      await _redundancyService.sendCriticalNotificationWithRedundancy(
        alertId: 'system_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: CriticalNotificationType.systemFailure,
      );
    } catch (e) {
      log('❌ Impossible d\'envoyer l\'alerte système: $e');
    }
  }

  /// Configurer les callbacks de monitoring
  void _setupSystemMonitoringCallbacks() {
    // TODO: Écouter les événements du système monitor
    // et réagir aux changements d'état critiques
  }

  /// Démarrer la surveillance de santé
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// Effectuer une vérification de santé
  Future<void> _performHealthCheck() async {
    try {
      // Vérifier l'état des services
      final redundancyStats = _redundancyService.getStatistics();
      final monitorStats = _systemMonitor.getStatistics();
      
      // Calculer le taux de fiabilité
      final reliabilityRate = _calculateReliabilityRate();
      
      // Déclencher des alertes si nécessaire
      if (reliabilityRate < 0.95) { // Moins de 95% de fiabilité
        await _sendSystemCriticalAlert(
          'Fiabilité dégradée',
          'Le taux de fiabilité des alertes est de ${(reliabilityRate * 100).toStringAsFixed(1)}%. '
          'Vérifiez votre connexion et les paramètres.',
        );
      }

      // Générer un rapport de fiabilité
      await _generateReliabilityReport();
      
    } catch (e) {
      log('❌ Erreur vérification santé: $e');
    }
  }

  /// Calculer le taux de fiabilité
  double _calculateReliabilityRate() {
    if (_totalAlertsGenerated == 0) return 1.0;
    return _totalAlertsDelivered / _totalAlertsGenerated;
  }

  /// Générer un rapport de fiabilité
  Future<void> _generateReliabilityReport() async {
    final report = AlertReliabilityReport(
      totalGenerated: _totalAlertsGenerated,
      totalDelivered: _totalAlertsDelivered,
      totalAcknowledged: _totalAlertsAcknowledged,
      reliabilityRate: _calculateReliabilityRate(),
      consecutiveFailures: _consecutiveFailures,
      isEmergencyMode: _isEmergencyMode,
      systemStatus: _systemMonitor.currentStatus,
      timestamp: DateTime.now(),
    );

    onReliabilityReport?.call(report);
    await _saveMetrics();
  }

  /// Démarrer le monitoring d'accusé de réception
  void _startAcknowledgmentMonitoring(
    AlertDeliveryAttempt attempt, 
    Duration timeout
  ) {
    Timer(timeout, () {
      if (attempt.acknowledgedAt == null) {
        log('⚠️ Timeout accusé de réception: ${attempt.alertId}');
        
        // Déclencher une nouvelle tentative
        _retryAlert(attempt);
      }
    });
  }

  /// Retry d'une alerte
  Future<void> _retryAlert(AlertDeliveryAttempt attempt) async {
    if (attempt.retryCount >= 3) {
      log('❌ Abandon après 3 tentatives: ${attempt.alertId}');
      return;
    }

    attempt.retryCount++;
    log('🔄 Retry ${attempt.retryCount} pour: ${attempt.alertId}');

    await sendCriticalAlert(
      alertId: '${attempt.alertId}_retry_${attempt.retryCount}',
      title: attempt.title,
      message: attempt.message,
      type: attempt.type,
      priority: attempt.priority,
      metadata: attempt.metadata,
    );
  }

  /// Convertir le type d'alerte
  CriticalNotificationType _convertToCriticalNotificationType(CriticalAlertType type) {
    switch (type) {
      case CriticalAlertType.dangerZoneEntry:
        return CriticalNotificationType.dangerZoneEntry;
      case CriticalAlertType.safeZoneExit:
        return CriticalNotificationType.safeZoneExit;
      case CriticalAlertType.systemFailure:
        return CriticalNotificationType.systemFailure;
      case CriticalAlertType.emergencyAlert:
        return CriticalNotificationType.emergencyAlert;
      case CriticalAlertType.serviceDown:
        return CriticalNotificationType.serviceDown;
    }
  }

  /// Charger les métriques
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalAlertsGenerated = prefs.getInt('total_alerts_generated') ?? 0;
      _totalAlertsDelivered = prefs.getInt('total_alerts_delivered') ?? 0;
      _totalAlertsAcknowledged = prefs.getInt('total_alerts_acknowledged') ?? 0;
    } catch (e) {
      log('❌ Erreur chargement métriques: $e');
    }
  }

  /// Sauvegarder les métriques
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_alerts_generated', _totalAlertsGenerated);
      await prefs.setInt('total_alerts_delivered', _totalAlertsDelivered);
      await prefs.setInt('total_alerts_acknowledged', _totalAlertsAcknowledged);
    } catch (e) {
      log('❌ Erreur sauvegarde métriques: $e');
    }
  }

  /// Obtenir les statistiques complètes
  Map<String, dynamic> getComprehensiveStatistics() {
    return {
      'unified_service': {
        'is_initialized': _isInitialized,
        'is_emergency_mode': _isEmergencyMode,
        'total_generated': _totalAlertsGenerated,
        'total_delivered': _totalAlertsDelivered,
        'total_acknowledged': _totalAlertsAcknowledged,
        'reliability_rate': _calculateReliabilityRate(),
        'consecutive_failures': _consecutiveFailures,
      },
      'redundancy_service': _redundancyService.getStatistics(),
      'system_monitor': _systemMonitor.getStatistics(),
    };
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();
    _emergencyModeTimer?.cancel();
    
    await _redundancyService.dispose();
    await _systemMonitor.dispose();
    
    _isInitialized = false;
    log('UnifiedCriticalAlertService: Disposed');
  }
}

/// Types d'alertes critiques
enum CriticalAlertType {
  dangerZoneEntry,
  safeZoneExit,
  systemFailure,
  emergencyAlert,
  serviceDown,
}

/// Priorité des alertes
enum AlertPriority {
  low,
  medium,
  high,
  critical,
}

/// Statut de livraison d'alerte
enum AlertDeliveryStatus {
  pending,
  sent,
  acknowledged,
  failed,
  timeout,
}

/// Tentative de livraison d'alerte
class AlertDeliveryAttempt {
  final String alertId;
  final String title;
  final String message;
  final CriticalAlertType type;
  final AlertPriority priority;
  final DateTime startTime;
  final Map<String, dynamic> metadata;
  
  AlertDeliveryStatus deliveryStatus = AlertDeliveryStatus.pending;
  DateTime? acknowledgedAt;
  String? errorMessage;
  int retryCount = 0;

  AlertDeliveryAttempt({
    required this.alertId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.startTime,
    required this.metadata,
  });

  String toJson() {
    return '{"alertId":"$alertId","title":"$title","message":"$message","type":"${type.toString()}","priority":"${priority.toString()}","startTime":"${startTime.toIso8601String()}","status":"${deliveryStatus.toString()}"}';
  }
}

/// Résultat de livraison d'alerte
class AlertDeliveryResult {
  final bool success;
  final String alertId;
  final Duration deliveryTime;
  final List<String> channels;
  final String? error;

  AlertDeliveryResult({
    required this.success,
    required this.alertId,
    required this.deliveryTime,
    this.channels = const [],
    this.error,
  });
}

/// Événement système critique
class CriticalSystemEvent {
  final CriticalSystemEventType type;
  final String message;
  final DateTime timestamp;
  final EventSeverity severity;

  CriticalSystemEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.severity,
  });
}

/// Types d'événements système critiques
enum CriticalSystemEventType {
  emergencyModeActivated,
  emergencyModeDeactivated,
  systemDegraded,
  systemRestored,
  reliabilityThresholdBreached,
}

/// Sévérité des événements
enum EventSeverity {
  info,
  warning,
  critical,
}

/// Rapport de fiabilité des alertes
class AlertReliabilityReport {
  final int totalGenerated;
  final int totalDelivered;
  final int totalAcknowledged;
  final double reliabilityRate;
  final int consecutiveFailures;
  final bool isEmergencyMode;
  final SystemHealthStatus systemStatus;
  final DateTime timestamp;

  AlertReliabilityReport({
    required this.totalGenerated,
    required this.totalDelivered,
    required this.totalAcknowledged,
    required this.reliabilityRate,
    required this.consecutiveFailures,
    required this.isEmergencyMode,
    required this.systemStatus,
    required this.timestamp,
  });
}