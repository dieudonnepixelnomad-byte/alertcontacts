import 'package:alertcontacts/core/services/local_notification_service.dart';
import 'package:alertcontacts/core/services/unified_alert_service.dart';
import 'package:alertcontacts/features/alertes/services/notification_config_service.dart' as config;
import 'package:flutter/foundation.dart';

/// Gestionnaire principal qui orchestre les services de notifications et d'alertes
/// Simplifie l'utilisation des services unifiés en fournissant une API haut niveau
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final UnifiedAlertService _alertService = UnifiedAlertService();
  final config.NotificationConfigService _configService = 
      config.NotificationConfigService();

  bool _isInitialized = false;

  /// Initialise tous les services de notifications et d'alertes
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🚀 Initialisation du NotificationManager...');

      // Initialiser les services en parallèle
      final results = await Future.wait([
        _notificationService.initialize(),
        _alertService.initialize(),
      ]);

      final notificationInitialized = results[0];
      final alertInitialized = results[1];

      if (notificationInitialized && alertInitialized) {
        _isInitialized = true;
        debugPrint('✅ NotificationManager initialisé avec succès');
        return true;
      } else {
        debugPrint('❌ Échec de l\'initialisation du NotificationManager');
        debugPrint('   - Notifications: $notificationInitialized');
        debugPrint('   - Alertes: $alertInitialized');
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ Erreur lors de l\'initialisation du NotificationManager: $e',
      );
      return false;
    }
  }

  /// Demande toutes les permissions nécessaires
  Future<bool> requestAllPermissions() async {
    try {
      final notificationPermissions = await _notificationService
          .requestPermissions();
      debugPrint('📱 Permissions notifications: $notificationPermissions');

      return notificationPermissions;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Vérifie si toutes les permissions sont accordées
  Future<bool> areAllPermissionsGranted() async {
    try {
      return await _notificationService.arePermissionsGranted();
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Déclenche une alerte complète pour une zone de danger
  /// Combine notification locale + alerte vocale/vibration
  Future<void> triggerDangerZoneAlert({
    required String zoneName,
    required int distanceMeters,
    required String severity, // 'low', 'medium', 'high', 'critical'
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationManager non initialisé');
      return;
    }

    // Vérifier si les notifications peuvent être envoyées (heures calmes)
    if (!await _configService.canSendNotification()) {
      debugPrint('🔇 Notification zone de danger bloquée (heures calmes)');
      return;
    }

    try {
      // Déterminer la priorité et l'intensité selon la sévérité
      final NotificationPriority notificationPriority;
      final VibrationIntensity vibrationIntensity;

      switch (severity.toLowerCase()) {
        case 'critical':
          notificationPriority = NotificationPriority.critical;
          vibrationIntensity = VibrationIntensity.critical;
          break;
        case 'high':
          notificationPriority = NotificationPriority.high;
          vibrationIntensity = VibrationIntensity.heavy;
          break;
        case 'medium':
          notificationPriority = NotificationPriority.normal;
          vibrationIntensity = VibrationIntensity.medium;
          break;
        default:
          notificationPriority = NotificationPriority.normal;
          vibrationIntensity = VibrationIntensity.light;
      }

      // Déclencher notification et alerte en parallèle
      await Future.wait([
        // Notification locale
        _notificationService.showNotification(
          NotificationConfig(
            title: '⚠️ Zone de danger détectée',
            body: 'Vous approchez de "$zoneName" à ${distanceMeters}m',
            type: NotificationType.dangerZone,
            priority: notificationPriority,
            enableVibration: true,
            enableSound: true,
            payload: 'danger_zone:$zoneName:$distanceMeters',
          ),
        ),

        // Alerte vocale et vibration
        _alertService.triggerDangerZoneAlert(
          zoneName: zoneName,
          distanceMeters: distanceMeters,
        ),
      ]);

      debugPrint(
        '🚨 Alerte zone de danger déclenchée: $zoneName ($distanceMeters m)',
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'alerte zone de danger: $e');
    }
  }

  /// Déclenche une alerte pour une sortie de zone de sécurité
  Future<void> triggerSafeZoneExitAlert({
    required String zoneName,
    required String contactName,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationManager non initialisé');
      return;
    }

    // Vérifier si les notifications peuvent être envoyées (heures calmes)
    if (!await _configService.canSendNotification()) {
      debugPrint('🔇 Notification zone de sécurité bloquée (heures calmes)');
      return;
    }

    try {
      await Future.wait([
        // Notification locale
        _notificationService.showNotification(
          NotificationConfig(
            title: '🛡️ Zone de sécurité',
            body: '$contactName a quitté "$zoneName"',
            type: NotificationType.safeZone,
            priority: NotificationPriority.normal,
            enableVibration: true,
            enableSound: true,
            payload: 'safe_zone_exit:$zoneName:$contactName',
          ),
        ),

        // Alerte vocale et vibration
        _alertService.triggerSafeZoneExitAlert(
          zoneName: zoneName,
          contactName: contactName,
        ),
      ]);

      debugPrint(
        '🛡️ Alerte sortie zone de sécurité déclenchée: $contactName a quitté $zoneName',
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'alerte sortie zone de sécurité: $e');
    }
  }

  /// Déclenche une alerte critique système
  Future<void> triggerCriticalSystemAlert({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationManager non initialisé');
      return;
    }

    // Vérifier si les notifications peuvent être envoyées (heures calmes)
    if (!await _configService.canSendNotification()) {
      debugPrint('🔇 Alerte critique bloquée (heures calmes)');
      return;
    }

    try {
      await Future.wait([
        // Notification locale critique
        _notificationService.showNotification(
          NotificationConfig(
            title: '🚨 $title',
            body: message,
            type: NotificationType.critical,
            priority: NotificationPriority.critical,
            enableVibration: true,
            enableSound: true,
            payload: 'critical_system:$title',
          ),
        ),

        // Alerte critique
        _alertService.triggerCriticalAlert(message: message),
      ]);

      debugPrint('🚨 Alerte critique système déclenchée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'alerte critique: $e');
    }
  }

  /// Envoie une notification simple sans alerte
  Future<void> sendSimpleNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.statusUpdate,
    NotificationPriority priority = NotificationPriority.normal,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationManager non initialisé');
      return;
    }

    // Vérifier si les notifications peuvent être envoyées (heures calmes)
    if (!await _configService.canSendNotification()) {
      debugPrint('🔇 Notification simple bloquée (heures calmes)');
      return;
    }

    try {
      await _notificationService.showNotification(
        NotificationConfig(
          title: title,
          body: body,
          type: type,
          priority: priority,
          enableVibration:
              priority == NotificationPriority.high ||
              priority == NotificationPriority.critical,
          enableSound:
              priority == NotificationPriority.high ||
              priority == NotificationPriority.critical,
          payload: payload,
        ),
      );

      debugPrint('📱 Notification simple envoyée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de notification: $e');
    }
  }

  /// Configure les paramètres globaux des alertes
  Future<void> configureAlertSettings({
    bool? voiceEnabled,
    bool? vibrationEnabled,
    double? voiceVolume,
    double? voicePitch,
    double? voiceRate,
    String? voiceLanguage,
  }) async {
    try {
      await _alertService.configureVoiceSettings(
        enabled: voiceEnabled,
        volume: voiceVolume,
        pitch: voicePitch,
        rate: voiceRate,
        language: voiceLanguage,
      );

      _alertService.configureVibrationSettings(enabled: vibrationEnabled);

      debugPrint('⚙️ Paramètres d\'alerte configurés');
    } catch (e) {
      debugPrint('❌ Erreur lors de la configuration des alertes: $e');
    }
  }

  /// Arrête toutes les alertes en cours
  Future<void> stopAllAlerts() async {
    try {
      await _alertService.stopAllAlerts();
      debugPrint('🛑 Toutes les alertes arrêtées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt des alertes: $e');
    }
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      debugPrint('🗑️ Toutes les notifications annulées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation des notifications: $e');
    }
  }

  /// Teste tous les systèmes d'alerte
  Future<void> testAllSystems() async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationManager non initialisé');
      return;
    }

    try {
      debugPrint('🧪 Test de tous les systèmes...');

      // Test notification simple
      await sendSimpleNotification(
        title: 'Test Notification',
        body: 'Test du système de notifications AlertContact',
        type: NotificationType.statusUpdate,
      );

      // Attendre un peu
      await Future.delayed(const Duration(seconds: 2));

      // Test alerte complète
      await _alertService.testAlerts();

      debugPrint('✅ Test de tous les systèmes terminé');
    } catch (e) {
      debugPrint('❌ Erreur lors du test des systèmes: $e');
    }
  }

  /// Getters pour l'état des services
  bool get isInitialized => _isInitialized;
  bool get isVoiceEnabled => _alertService.isVoiceEnabled;
  bool get isVibrationEnabled => _alertService.isVibrationEnabled;
  bool get isVibrationSupported => _alertService.isVibrationSupported;
  bool get isSpeaking => _alertService.isSpeaking;

  /// Dispose de tous les services
  Future<void> dispose() async {
    try {
      await stopAllAlerts();
      await cancelAllNotifications();
      await _alertService.dispose();
      _notificationService.dispose();
      _isInitialized = false;
      debugPrint('🗑️ NotificationManager disposé');
    } catch (e) {
      debugPrint('❌ Erreur lors du dispose du NotificationManager: $e');
    }
  }
}
