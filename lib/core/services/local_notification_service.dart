import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alertcontacts/features/alertes/services/notification_config_service.dart' as config;
import 'global_navigation_service.dart';

/// Types de notifications disponibles
enum NotificationType {
  dangerZone,
  safeZone,
  locationSharing,
  healthAlert,
  statusUpdate,
  critical,
}

/// Priorités des notifications
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

/// Configuration d'une notification
class NotificationConfig {
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final bool enableVibration;
  final bool enableSound;
  final String? payload;
  final Map<String, dynamic>? data;

  const NotificationConfig({
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.enableVibration = true,
    this.enableSound = true,
    this.payload,
    this.data,
  });
}

/// Service unifié pour la gestion de toutes les notifications locales
/// Centralise l'initialisation, la configuration et l'envoi des notifications
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final config.NotificationConfigService _configService = 
      config.NotificationConfigService();

  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Configuration Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? result = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        await _createNotificationChannels();
        _isInitialized = true;
        debugPrint('✅ LocalNotificationService initialisé avec succès');
      }

      return result ?? false;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
      return false;
    }
  }

  /// Crée les canaux de notification Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final List<AndroidNotificationChannel> channels = [
      // Canal pour les zones de danger (critique)
      const AndroidNotificationChannel(
        'danger_zone_channel',
        'Zones de Danger',
        description: 'Alertes critiques pour les zones dangereuses',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
        // sound: RawResourceAndroidNotificationSound('danger_alert'), // Désactivé car fichier manquant
        playSound: true,
      ),

      // Canal pour les zones de sécurité
      const AndroidNotificationChannel(
        'safe_zone_channel',
        'Zones de Sécurité',
        description: 'Notifications pour les zones de sécurité',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF00FF00),
        // sound: RawResourceAndroidNotificationSound('safe_zone_alert'), // Désactivé car fichier manquant
        playSound: true,
      ),

      // Canal pour le partage de localisation
      const AndroidNotificationChannel(
        'location_sharing_channel',
        'Partage de Localisation',
        description: 'Notifications de partage de localisation',
        importance: Importance.defaultImportance,
        enableVibration: false,
        enableLights: false,
        playSound: false,
      ),

      // Canal pour les alertes de santé du système
      const AndroidNotificationChannel(
        'health_alert_channel',
        'Alertes Système',
        description: 'Alertes de santé et de statut du système',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF9800),
        playSound: true,
      ),

      // Canal pour les mises à jour de statut
      const AndroidNotificationChannel(
        'status_update_channel',
        'Mises à Jour',
        description: 'Mises à jour de statut et informations générales',
        importance: Importance.low,
        enableVibration: false,
        enableLights: false,
        playSound: false,
      ),

      // Canal pour les notifications critiques
      const AndroidNotificationChannel(
        'critical_alert_channel',
        'Alertes Critiques',
        description: 'Alertes critiques nécessitant une attention immédiate',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
        sound: RawResourceAndroidNotificationSound('critical_alert'),
        playSound: true,
      ),
    ];

    // Créer tous les canaux
    for (final channel in channels) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('✅ Canaux de notification Android créés');
  }

  /// Gère les taps sur les notifications
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tappée: ${response.payload}');
    
    // Gérer la navigation basée sur le payload
    GlobalNavigationService.handleNotificationNavigation(response.payload);
  }

  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// Vérifie si les permissions sont accordées
  Future<bool> arePermissionsGranted() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      final permissions = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions != null;
    }
    return true;
  }

  /// Envoie une notification locale
  Future<void> showNotification(NotificationConfig config) async {
    // Vérifier si les notifications peuvent être envoyées (heures calmes)
    if (!await _configService.canSendNotification()) {
      debugPrint('🔇 Notification locale bloquée (heures calmes): ${config.title}');
      return;
    }

    if (!_isInitialized) {
      debugPrint('⚠️ Service non initialisé, tentative d\'initialisation...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ Impossible d\'initialiser le service de notifications');
        return;
      }
    }

    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _getChannelId(config.type),
        _getChannelName(config.type),
        channelDescription: _getChannelDescription(config.type),
        importance: _getAndroidImportance(config.priority),
        priority: _getAndroidPriority(config.priority),
        enableVibration: config.enableVibration,
        playSound: config.enableSound,
        sound: config.enableSound ? _getNotificationSound(config.type) : null,
        ledColor: _getLedColor(config.type),
        ledOnMs: 1000, // LED allumée pendant 1 seconde
        ledOffMs: 500, // LED éteinte pendant 0.5 seconde
        enableLights: config.priority == NotificationPriority.critical || 
                     config.type == NotificationType.dangerZone,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: config.enableSound,
        sound: config.enableSound ? _getIOSSound(config.type) : null,
        interruptionLevel: _getIOSInterruptionLevel(config.priority),
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        config.title,
        config.body,
        platformDetails,
        payload: config.payload,
      );

      debugPrint('✅ Notification envoyée: ${config.title}');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Obtient l'ID du canal pour un type de notification
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.dangerZone:
        return 'danger_zone_channel';
      case NotificationType.safeZone:
        return 'safe_zone_channel';
      case NotificationType.locationSharing:
        return 'location_sharing_channel';
      case NotificationType.healthAlert:
        return 'health_alert_channel';
      case NotificationType.statusUpdate:
        return 'status_update_channel';
      case NotificationType.critical:
        return 'critical_alert_channel';
    }
  }

  /// Obtient le nom du canal pour un type de notification
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.dangerZone:
        return 'Zones de Danger';
      case NotificationType.safeZone:
        return 'Zones de Sécurité';
      case NotificationType.locationSharing:
        return 'Partage de Localisation';
      case NotificationType.healthAlert:
        return 'Alertes Système';
      case NotificationType.statusUpdate:
        return 'Mises à Jour';
      case NotificationType.critical:
        return 'Alertes Critiques';
    }
  }

  /// Obtient la description du canal pour un type de notification
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.dangerZone:
        return 'Alertes critiques pour les zones dangereuses';
      case NotificationType.safeZone:
        return 'Notifications pour les zones de sécurité';
      case NotificationType.locationSharing:
        return 'Notifications de partage de localisation';
      case NotificationType.healthAlert:
        return 'Alertes de santé et de statut du système';
      case NotificationType.statusUpdate:
        return 'Mises à jour de statut et informations générales';
      case NotificationType.critical:
        return 'Alertes critiques nécessitant une attention immédiate';
    }
  }

  /// Convertit la priorité en importance Android
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  /// Convertit la priorité en priorité Android
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.critical:
        return Priority.max;
    }
  }

  /// Obtient le niveau d'interruption iOS
  InterruptionLevel _getIOSInterruptionLevel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return InterruptionLevel.passive;
      case NotificationPriority.normal:
        return InterruptionLevel.active;
      case NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case NotificationPriority.critical:
        return InterruptionLevel.critical;
    }
  }

  /// Obtient le son de notification Android
  RawResourceAndroidNotificationSound? _getNotificationSound(NotificationType type) {
    // Sons personnalisés désactivés car fichiers manquants
    // Utilise le son par défaut du système
    return null;
    
    /* Configuration originale (fichiers audio manquants) :
    switch (type) {
      case NotificationType.dangerZone:
      case NotificationType.critical:
        return const RawResourceAndroidNotificationSound('danger_alert');
      case NotificationType.safeZone:
        return const RawResourceAndroidNotificationSound('safe_zone_alert');
      case NotificationType.healthAlert:
        return const RawResourceAndroidNotificationSound('health_alert');
      default:
        return null;
    }
    */
  }

  /// Obtient le son de notification iOS
  String? _getIOSSound(NotificationType type) {
    // Sons personnalisés désactivés car fichiers manquants
    // Utilise le son par défaut du système
    return null;
    
    /* Configuration originale (fichiers audio manquants) :
    switch (type) {
      case NotificationType.dangerZone:
      case NotificationType.critical:
        return 'danger_alert.wav';
      case NotificationType.safeZone:
        return 'safe_zone_alert.wav';
      case NotificationType.healthAlert:
        return 'health_alert.wav';
      default:
        return null;
    }
    */
  }

  /// Obtient la couleur LED pour Android
  Color? _getLedColor(NotificationType type) {
    switch (type) {
      case NotificationType.dangerZone:
      case NotificationType.critical:
        return const Color(0xFFFF0000); // Rouge
      case NotificationType.safeZone:
        return const Color(0xFF00FF00); // Vert
      case NotificationType.healthAlert:
        return const Color(0xFFFF9800); // Orange
      default:
        return null;
    }
  }

  /// Dispose des ressources
  void dispose() {
    _isInitialized = false;
    debugPrint('🗑️ LocalNotificationService disposé');
  }
}