import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de configuration des notifications d'alertes
class NotificationConfigService {
  static final NotificationConfigService _instance =
      NotificationConfigService._internal();
  factory NotificationConfigService() => _instance;
  NotificationConfigService._internal();

  // Clés pour SharedPreferences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyVoiceAlertsEnabled = 'voice_alerts_enabled';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietHoursStart = 'quiet_hours_start';
  static const String _keyQuietHoursEnd = 'quiet_hours_end';
  static const String _keyDiscreteMode = 'discrete_mode';
  // Cooldown supprimé - géré côté backend
  static const String _keyWarningDistance = 'warning_distance';
  static const String _keyCriticalDistance = 'critical_distance';

  // Valeurs par défaut
  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const bool _defaultVoiceAlertsEnabled = true;
  static const bool _defaultQuietHoursEnabled = false;
  static const int _defaultQuietHoursStart = 22; // 22h00
  static const int _defaultQuietHoursEnd = 7; // 07h00
  static const bool _defaultDiscreteMode = false;
  // Cooldown par défaut supprimé - géré côté backend
  static const double _defaultWarningDistance = 200.0; // mètres
  static const double _defaultCriticalDistance = 50.0; // mètres

  SharedPreferences? _prefs;

  /// Initialiser le service
  Future<void> initialize() async {
    debugPrint('NotificationConfigService: Initializing...');
    _prefs = await SharedPreferences.getInstance();
    debugPrint('NotificationConfigService: Initialized successfully');
  }

  /// Vérifier si les notifications sont activées
  bool get notificationsEnabled {
    final value =
        _prefs?.getBool(_keyNotificationsEnabled) ??
        _defaultNotificationsEnabled;
    debugPrint('NotificationConfigService: notificationsEnabled = $value');
    return value;
  }

  /// Activer/désactiver les notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    debugPrint(
      'NotificationConfigService: Setting notificationsEnabled to $enabled',
    );
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
    debugPrint(
      'NotificationConfigService: Notifications ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Vérifier si les vibrations sont activées
  bool get vibrationEnabled {
    final value =
        _prefs?.getBool(_keyVibrationEnabled) ?? _defaultVibrationEnabled;
    debugPrint('NotificationConfigService: vibrationEnabled = $value');
    return value;
  }

  /// Activer/désactiver les vibrations
  Future<void> setVibrationEnabled(bool enabled) async {
    debugPrint(
      'NotificationConfigService: Setting vibrationEnabled to $enabled',
    );
    await _prefs?.setBool(_keyVibrationEnabled, enabled);
    debugPrint(
      'NotificationConfigService: Vibration ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Vérifier si les alertes vocales sont activées
  bool get voiceAlertsEnabled {
    final value =
        _prefs?.getBool(_keyVoiceAlertsEnabled) ?? _defaultVoiceAlertsEnabled;
    debugPrint('NotificationConfigService: voiceAlertsEnabled = $value');
    return value;
  }

  /// Activer/désactiver les alertes vocales
  Future<void> setVoiceAlertsEnabled(bool enabled) async {
    debugPrint(
      'NotificationConfigService: Setting voiceAlertsEnabled to $enabled',
    );
    await _prefs?.setBool(_keyVoiceAlertsEnabled, enabled);
    debugPrint(
      'NotificationConfigService: Voice alerts ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Vérifier si les heures calmes sont activées
  bool get quietHoursEnabled {
    final value =
        _prefs?.getBool(_keyQuietHoursEnabled) ?? _defaultQuietHoursEnabled;
    debugPrint('NotificationConfigService: quietHoursEnabled = $value');
    return value;
  }

  /// Activer/désactiver les heures calmes
  Future<void> setQuietHoursEnabled(bool enabled) async {
    debugPrint(
      'NotificationConfigService: Setting quietHoursEnabled to $enabled',
    );
    await _prefs?.setBool(_keyQuietHoursEnabled, enabled);
    debugPrint(
      'NotificationConfigService: Quiet hours ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Obtenir l'heure de début des heures calmes (0-23)
  int get quietHoursStart {
    final value =
        _prefs?.getInt(_keyQuietHoursStart) ?? _defaultQuietHoursStart;
    debugPrint('NotificationConfigService: quietHoursStart = $value');
    return value;
  }

  /// Définir l'heure de début des heures calmes
  Future<void> setQuietHoursStart(int hour) async {
    debugPrint('NotificationConfigService: Setting quietHoursStart to $hour');
    if (hour >= 0 && hour <= 23) {
      await _prefs?.setInt(_keyQuietHoursStart, hour);
      debugPrint(
        'NotificationConfigService: Quiet hours start set to $hour:00',
      );
    } else {
      debugPrint(
        'NotificationConfigService: Invalid quietHoursStart value: $hour',
      );
    }
  }

  /// Obtenir l'heure de fin des heures calmes (0-23)
  int get quietHoursEnd {
    final value = _prefs?.getInt(_keyQuietHoursEnd) ?? _defaultQuietHoursEnd;
    debugPrint('NotificationConfigService: quietHoursEnd = $value');
    return value;
  }

  /// Définir l'heure de fin des heures calmes
  Future<void> setQuietHoursEnd(int hour) async {
    debugPrint('NotificationConfigService: Setting quietHoursEnd to $hour');
    if (hour >= 0 && hour <= 23) {
      await _prefs?.setInt(_keyQuietHoursEnd, hour);
      debugPrint('NotificationConfigService: Quiet hours end set to $hour:00');
    } else {
      debugPrint(
        'NotificationConfigService: Invalid quietHoursEnd value: $hour',
      );
    }
  }

  /// Vérifier si le mode discret est activé
  bool get discreteMode {
    final value = _prefs?.getBool(_keyDiscreteMode) ?? _defaultDiscreteMode;
    debugPrint('NotificationConfigService: discreteMode = $value');
    return value;
  }

  /// Activer/désactiver le mode discret
  Future<void> setDiscreteMode(bool enabled) async {
    debugPrint('NotificationConfigService: Setting discreteMode to $enabled');
    await _prefs?.setBool(_keyDiscreteMode, enabled);
    debugPrint(
      'NotificationConfigService: Discrete mode ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Méthodes de cooldown supprimées - géré côté backend

  /// Obtenir la distance d'alerte (en mètres)
  double get warningDistance {
    final value =
        _prefs?.getDouble(_keyWarningDistance) ?? _defaultWarningDistance;
    debugPrint('NotificationConfigService: warningDistance = $value');
    return value;
  }

  /// Définir la distance d'alerte
  Future<void> setWarningDistance(double meters) async {
    debugPrint('NotificationConfigService: Setting warningDistance to $meters');
    if (meters >= 50 && meters <= 1000) {
      await _prefs?.setDouble(_keyWarningDistance, meters);
      debugPrint(
        'NotificationConfigService: Warning distance set to ${meters}m',
      );
    } else {
      debugPrint(
        'NotificationConfigService: Invalid warningDistance value: $meters',
      );
    }
  }

  /// Obtenir la distance critique (en mètres)
  double get criticalDistance {
    final value =
        _prefs?.getDouble(_keyCriticalDistance) ?? _defaultCriticalDistance;
    debugPrint('NotificationConfigService: criticalDistance = $value');
    return value;
  }

  /// Définir la distance critique
  Future<void> setCriticalDistance(double meters) async {
    debugPrint(
      'NotificationConfigService: Setting criticalDistance to $meters',
    );
    if (meters >= 10 && meters <= 200) {
      await _prefs?.setDouble(_keyCriticalDistance, meters);
      debugPrint(
        'NotificationConfigService: Critical distance set to ${meters}m',
      );
    } else {
      debugPrint(
        'NotificationConfigService: Invalid criticalDistance value: $meters',
      );
    }
  }

  /// Vérifier si nous sommes dans les heures calmes
  bool get isInQuietHours {
    debugPrint('NotificationConfigService: Checking isInQuietHours...');
    if (!quietHoursEnabled) {
      debugPrint(
        'NotificationConfigService: Quiet hours disabled, returning false',
      );
      return false;
    }

    final now = DateTime.now();
    final currentHour = now.hour;
    final start = quietHoursStart;
    final end = quietHoursEnd;

    debugPrint(
      'NotificationConfigService: Current hour: $currentHour, Start: $start, End: $end',
    );

    bool result;
    if (start < end) {
      // Heures calmes dans la même journée (ex: 22h-7h)
      result = currentHour >= start && currentHour < end;
    } else {
      // Heures calmes qui traversent minuit (ex: 22h-7h)
      result = currentHour >= start || currentHour < end;
    }
    debugPrint('NotificationConfigService: isInQuietHours = $result');
    return result;
  }

  /// Vérifier si une notification peut être envoyée
  bool canSendNotification() {
    debugPrint('NotificationConfigService: Checking canSendNotification...');
    if (!notificationsEnabled) {
      debugPrint(
        'NotificationConfigService: Notifications disabled, returning false',
      );
      return false;
    }
    if (isInQuietHours && discreteMode) {
      debugPrint(
        'NotificationConfigService: In quiet hours with discrete mode, returning false',
      );
      return false;
    }
    debugPrint('NotificationConfigService: canSendNotification = true');
    return true;
  }

  /// Obtenir le type de notification à envoyer
  NotificationType getNotificationType() {
    debugPrint('NotificationConfigService: Getting notification type...');
    if (!canSendNotification()) {
      debugPrint(
        'NotificationConfigService: Cannot send notification, returning NotificationType.none',
      );
      return NotificationType.none;
    }

    if (isInQuietHours) {
      debugPrint(
        'NotificationConfigService: In quiet hours, returning NotificationType.discrete',
      );
      return NotificationType.discrete;
    }

    if (discreteMode) {
      debugPrint(
        'NotificationConfigService: Discrete mode enabled, returning NotificationType.discrete',
      );
      return NotificationType.discrete;
    }

    debugPrint('NotificationConfigService: Returning NotificationType.full');
    return NotificationType.full;
  }

  /// Obtenir la configuration complète
  Map<String, dynamic> getConfiguration() {
    debugPrint('NotificationConfigService: Getting full configuration...');
    final config = {
      'notifications_enabled': notificationsEnabled,
      'vibration_enabled': vibrationEnabled,
      'voice_alerts_enabled': voiceAlertsEnabled,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'discrete_mode': discreteMode,
      // 'notification_cooldown' supprimé - géré côté backend
      'warning_distance': warningDistance,
      'critical_distance': criticalDistance,
      'is_in_quiet_hours': isInQuietHours,
    };
    debugPrint('NotificationConfigService: Configuration retrieved: $config');
    return config;
  }

  /// Réinitialiser la configuration aux valeurs par défaut
  Future<void> resetToDefaults() async {
    debugPrint('NotificationConfigService: Resetting to defaults...');
    await _prefs?.setBool(
      _keyNotificationsEnabled,
      _defaultNotificationsEnabled,
    );
    await _prefs?.setBool(_keyVibrationEnabled, _defaultVibrationEnabled);
    await _prefs?.setBool(_keyVoiceAlertsEnabled, _defaultVoiceAlertsEnabled);
    await _prefs?.setBool(_keyQuietHoursEnabled, _defaultQuietHoursEnabled);
    await _prefs?.setInt(_keyQuietHoursStart, _defaultQuietHoursStart);
    await _prefs?.setInt(_keyQuietHoursEnd, _defaultQuietHoursEnd);
    await _prefs?.setBool(_keyDiscreteMode, _defaultDiscreteMode);
    // Cooldown supprimé - géré côté backend
    await _prefs?.setDouble(_keyWarningDistance, _defaultWarningDistance);
    await _prefs?.setDouble(_keyCriticalDistance, _defaultCriticalDistance);

    debugPrint('NotificationConfigService: Configuration reset to defaults');
  }

  /// Exporter la configuration
  Map<String, dynamic> exportConfiguration() {
    debugPrint('NotificationConfigService: Exporting configuration...');
    final config = getConfiguration();
    debugPrint('NotificationConfigService: Configuration exported: $config');
    return config;
  }

  /// Importer une configuration
  Future<void> importConfiguration(Map<String, dynamic> config) async {
    debugPrint('NotificationConfigService: Importing configuration: $config');
    if (config.containsKey('notifications_enabled')) {
      await setNotificationsEnabled(config['notifications_enabled'] as bool);
    }
    if (config.containsKey('vibration_enabled')) {
      await setVibrationEnabled(config['vibration_enabled'] as bool);
    }
    if (config.containsKey('voice_alerts_enabled')) {
      await setVoiceAlertsEnabled(config['voice_alerts_enabled'] as bool);
    }
    if (config.containsKey('quiet_hours_enabled')) {
      await setQuietHoursEnabled(config['quiet_hours_enabled'] as bool);
    }
    if (config.containsKey('quiet_hours_start')) {
      await setQuietHoursStart(config['quiet_hours_start'] as int);
    }
    if (config.containsKey('quiet_hours_end')) {
      await setQuietHoursEnd(config['quiet_hours_end'] as int);
    }
    if (config.containsKey('discrete_mode')) {
      await setDiscreteMode(config['discrete_mode'] as bool);
    }
    // Cooldown supprimé - géré côté backend
    if (config.containsKey('warning_distance')) {
      await setWarningDistance(config['warning_distance'] as double);
    }
    if (config.containsKey('critical_distance')) {
      await setCriticalDistance(config['critical_distance'] as double);
    }

    debugPrint('NotificationConfigService: Configuration imported');
  }
}

/// Types de notifications
enum NotificationType {
  none, // Aucune notification
  discrete, // Notification discrète (vibration seulement)
  full, // Notification complète (son + vibration + voix)
}
