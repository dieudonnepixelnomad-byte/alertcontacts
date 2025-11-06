import 'package:flutter/foundation.dart';
import 'notification_config_service.dart';

/// Service d'alertes simplifié
/// 
/// Ce service gère uniquement la configuration des notifications.
/// La surveillance des zones et la détection de proximité sont gérées par le backend.
class AlertService extends ChangeNotifier {
  // Services
  final NotificationConfigService _configService = NotificationConfigService();

  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;

  /// Initialiser le service d'alertes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser le service de configuration
      await _configService.initialize();

      _isInitialized = true;
      debugPrint('AlertService: Initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AlertService: Initialization error: $e');
      rethrow;
    }
  }

  /// Obtenir la configuration des notifications
  NotificationConfigService get notificationConfig => _configService;

  /// Obtenir les statistiques du service
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'notificationConfig': {
        'notificationType': _configService.getNotificationType().name,
        'vibrationsEnabled': _configService.vibrationEnabled,
        'voiceAlertsEnabled': _configService.voiceAlertsEnabled,
      },
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}