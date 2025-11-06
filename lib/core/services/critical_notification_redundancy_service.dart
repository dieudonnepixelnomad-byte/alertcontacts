// lib/core/services/critical_notification_redundancy_service.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service de redondance critique pour les notifications de sécurité
/// Implémente plusieurs canaux de fallback pour garantir la réception
/// des alertes critiques même en cas de défaillance du système principal
class CriticalNotificationRedundancyService {
  static final CriticalNotificationRedundancyService _instance = 
      CriticalNotificationRedundancyService._internal();
  factory CriticalNotificationRedundancyService() => _instance;
  CriticalNotificationRedundancyService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  
  // Configuration critique
  static const Duration _maxRetryDuration = Duration(minutes: 5);
  static const Duration _retryInterval = Duration(seconds: 10);
  static const int _maxRetryAttempts = 30; // 5 minutes / 10 secondes
  static const String _criticalChannelId = 'critical_redundancy';
  static const String _criticalChannelName = 'Alertes Critiques Redondantes';
  
  // État des tentatives
  final Map<String, CriticalNotificationAttempt> _activeAttempts = {};
  
  /// Initialiser le service de redondance
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeNotifications();
      await _initializeTTS();
      _startHealthMonitoring();
      
      _isInitialized = true;
      log('CriticalNotificationRedundancyService: Initialized successfully');
    } catch (e) {
      log('CriticalNotificationRedundancyService: Initialization error: $e');
      rethrow;
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeNotifications() async {
    const androidChannel = AndroidNotificationChannel(
      _criticalChannelId,
      _criticalChannelName,
      description: 'Notifications critiques avec redondance maximale',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
      ledColor: Colors.red,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Initialiser le TTS
  Future<void> _initializeTTS() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.4); // Lent pour urgence
    await _tts.setVolume(1.0); // Volume maximum
    await _tts.setPitch(1.2); // Pitch élevé pour attirer l'attention
  }

  /// Envoyer une notification critique avec redondance maximale
  Future<void> sendCriticalNotificationWithRedundancy({
    required String alertId,
    required String title,
    required String message,
    required CriticalNotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      log('⚠️ Service non initialisé, tentative d\'envoi direct');
      await _sendDirectNotification(title, message);
      return;
    }

    // Créer une tentative de notification critique
    final attempt = CriticalNotificationAttempt(
      alertId: alertId,
      title: title,
      message: message,
      type: type,
      metadata: metadata ?? {},
      startTime: DateTime.now(),
    );

    _activeAttempts[alertId] = attempt;
    
    log('🚨 Démarrage notification critique redondante: $alertId');
    
    // Lancer tous les canaux en parallèle
    await Future.wait([
      _sendViaLocalNotification(attempt),
      _sendViaVibration(attempt),
      _sendViaVoiceAlert(attempt),
      _sendViaPersistentAlert(attempt),
    ]);

    // Démarrer les tentatives répétées
    _startRetryLoop(attempt);
  }

  /// Canal 1: Notification locale avec paramètres maximaux
  Future<void> _sendViaLocalNotification(CriticalNotificationAttempt attempt) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _criticalChannelId,
        _criticalChannelName,
        channelDescription: 'Alerte critique de sécurité',
        importance: Importance.max,
        priority: Priority.max,
        autoCancel: false, // Ne pas supprimer automatiquement
        ongoing: true, // Notification persistante
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('emergency_alert'),
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        color: Colors.red,
        colorized: true,
        styleInformation: BigTextStyleInformation(
          '🚨 ALERTE CRITIQUE 🚨\n\n${attempt.message}\n\nCette alerte nécessite votre attention immédiate.',
          contentTitle: '🚨 ${attempt.title}',
          summaryText: 'AlertContact - Sécurité',
        ),
        actions: [
          const AndroidNotificationAction(
            'acknowledge',
            'J\'ai vu l\'alerte',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'emergency',
            'Appeler les secours',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'emergency_alert.wav',
        interruptionLevel: InterruptionLevel.critical,
        threadIdentifier: 'critical_security',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        attempt.alertId.hashCode,
        '🚨 ${attempt.title}',
        attempt.message,
        platformDetails,
        payload: 'critical:${attempt.alertId}',
      );

      attempt.recordSuccess('local_notification');
      log('✅ Notification locale envoyée: ${attempt.alertId}');
    } catch (e) {
      attempt.recordFailure('local_notification', e.toString());
      log('❌ Échec notification locale: $e');
    }
  }

  /// Canal 2: Vibration d'urgence
  Future<void> _sendViaVibration(CriticalNotificationAttempt attempt) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Pattern d'urgence: 3 vibrations longues
        const pattern = [0, 1000, 200, 1000, 200, 1000, 500];
        
        for (int i = 0; i < 3; i++) {
          await Vibration.vibrate(pattern: pattern);
          await Future.delayed(const Duration(seconds: 2));
        }
        
        attempt.recordSuccess('vibration');
        log('✅ Vibration d\'urgence envoyée: ${attempt.alertId}');
      }
    } catch (e) {
      attempt.recordFailure('vibration', e.toString());
      log('❌ Échec vibration: $e');
    }
  }

  /// Canal 3: Alerte vocale
  Future<void> _sendViaVoiceAlert(CriticalNotificationAttempt attempt) async {
    try {
      final voiceMessage = 'Alerte critique ! ${attempt.title}. ${attempt.message}. '
          'Cette alerte nécessite votre attention immédiate.';
      
      // Répéter 3 fois
      for (int i = 0; i < 3; i++) {
        await _tts.speak(voiceMessage);
        await Future.delayed(const Duration(seconds: 2));
      }
      
      attempt.recordSuccess('voice_alert');
      log('✅ Alerte vocale envoyée: ${attempt.alertId}');
    } catch (e) {
      attempt.recordFailure('voice_alert', e.toString());
      log('❌ Échec alerte vocale: $e');
    }
  }

  /// Canal 4: Alerte persistante (notification qui ne disparaît pas)
  Future<void> _sendViaPersistentAlert(CriticalNotificationAttempt attempt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertData = {
        'id': attempt.alertId,
        'title': attempt.title,
        'message': attempt.message,
        'timestamp': attempt.startTime.toIso8601String(),
        'acknowledged': false,
      };
      
      await prefs.setString('persistent_alert_${attempt.alertId}', 
          alertData.toString());
      
      attempt.recordSuccess('persistent_alert');
      log('✅ Alerte persistante sauvegardée: ${attempt.alertId}');
    } catch (e) {
      attempt.recordFailure('persistent_alert', e.toString());
      log('❌ Échec alerte persistante: $e');
    }
  }

  /// Démarrer la boucle de retry
  void _startRetryLoop(CriticalNotificationAttempt attempt) {
    Timer.periodic(_retryInterval, (timer) {
      if (attempt.isExpired(_maxRetryDuration) || 
          attempt.retryCount >= _maxRetryAttempts ||
          attempt.isAcknowledged) {
        timer.cancel();
        _activeAttempts.remove(attempt.alertId);
        log('🔄 Fin des tentatives pour: ${attempt.alertId}');
        return;
      }

      attempt.retryCount++;
      log('🔄 Tentative ${attempt.retryCount} pour: ${attempt.alertId}');
      
      // Relancer tous les canaux
      _sendViaLocalNotification(attempt);
      _sendViaVibration(attempt);
      _sendViaVoiceAlert(attempt);
    });
  }

  /// Envoyer une notification directe (fallback ultime)
  Future<void> _sendDirectNotification(String title, String message) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch,
        '🚨 $title',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_fallback',
            'Urgence Fallback',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
      );
    } catch (e) {
      log('❌ Échec notification directe: $e');
    }
  }

  /// Accuser réception d'une alerte
  Future<void> acknowledgeAlert(String alertId) async {
    final attempt = _activeAttempts[alertId];
    if (attempt != null) {
      attempt.isAcknowledged = true;
      log('✅ Alerte accusée réception: $alertId');
      
      // Sauvegarder l'accusé de réception
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('alert_acknowledged_$alertId', true);
    }
  }

  /// Surveillance de santé
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performHealthCheck();
    });
  }

  /// Vérification de santé
  void _performHealthCheck() {
    final now = DateTime.now();
    final expiredAttempts = _activeAttempts.values
        .where((attempt) => attempt.isExpired(_maxRetryDuration))
        .toList();

    for (final attempt in expiredAttempts) {
      log('⚠️ Alerte expirée sans accusé de réception: ${attempt.alertId}');
      _activeAttempts.remove(attempt.alertId);
    }
  }

  /// Obtenir les statistiques
  Map<String, dynamic> getStatistics() {
    return {
      'active_attempts': _activeAttempts.length,
      'total_attempts': _activeAttempts.values.length,
      'success_rate': _calculateSuccessRate(),
      'is_initialized': _isInitialized,
    };
  }

  double _calculateSuccessRate() {
    if (_activeAttempts.isEmpty) return 1.0;
    
    final totalChannels = _activeAttempts.values
        .map((a) => a.successfulChannels.length)
        .fold(0, (a, b) => a + b);
    final totalAttempts = _activeAttempts.length * 4; // 4 canaux
    
    return totalAttempts > 0 ? totalChannels / totalAttempts : 0.0;
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _healthCheckTimer?.cancel();
    await _tts.stop();
    _isInitialized = false;
    log('CriticalNotificationRedundancyService: Disposed');
  }
}

/// Tentative de notification critique
class CriticalNotificationAttempt {
  final String alertId;
  final String title;
  final String message;
  final CriticalNotificationType type;
  final Map<String, dynamic> metadata;
  final DateTime startTime;
  
  int retryCount = 0;
  bool isAcknowledged = false;
  final Set<String> successfulChannels = {};
  final Map<String, String> failedChannels = {};

  CriticalNotificationAttempt({
    required this.alertId,
    required this.title,
    required this.message,
    required this.type,
    required this.metadata,
    required this.startTime,
  });

  void recordSuccess(String channel) {
    successfulChannels.add(channel);
  }

  void recordFailure(String channel, String error) {
    failedChannels[channel] = error;
  }

  bool isExpired(Duration maxDuration) {
    return DateTime.now().difference(startTime) > maxDuration;
  }
}

/// Types de notifications critiques
enum CriticalNotificationType {
  dangerZoneEntry,
  safeZoneExit,
  systemFailure,
  emergencyAlert,
  serviceDown,
}