import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de notifications persistantes pour indiquer l'état des services de surveillance
/// Fournit une transparence complète sur les services actifs pour rassurer l'utilisateur
class PersistentStatusNotificationService {
  static final PersistentStatusNotificationService _instance =
      PersistentStatusNotificationService._internal();
  factory PersistentStatusNotificationService() => _instance;
  PersistentStatusNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Timer? _statusUpdateTimer;

  // IDs de notification pour éviter les conflits
  static const int _statusNotificationId = 9001;
  static const String _channelId = 'service_status';
  static const String _channelName = 'État des services';
  static const String _channelDescription =
      'Notifications persistantes indiquant l\'état des services de surveillance';

  // Clés de préférences
  static const String _keyStatusNotificationEnabled =
      'status_notification_enabled';
  static const String _keyLastStatusUpdate = 'last_status_update';

  // État des services
  ServiceStatus _geolocationStatus = ServiceStatus.starting;
  ServiceStatus _geofencingStatus = ServiceStatus.starting;
  ServiceStatus _backgroundLocationStatus = ServiceStatus.starting;
  int _monitoredDangerZones = 0;
  int _monitoredSafeZones = 0;
  DateTime? _lastLocationUpdate;

  /// Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeNotifications();
      await _loadSettings();

      // Démarrer les mises à jour périodiques du statut
      _startPeriodicStatusUpdates();

      // Vérifier l'état réel des services après un délai pour permettre l'initialisation
      Future.delayed(const Duration(seconds: 2), () {
        _checkAndUpdateRealServiceStatus();
      });

      _isInitialized = true;
      log('PersistentStatusNotificationService: Initialized successfully');
    } catch (e) {
      log('PersistentStatusNotificationService: Initialization error: $e');
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission:
          false, // Pas d'alerte pour les notifications de statut
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Créer le canal de notification Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Importance faible pour ne pas déranger
      enableVibration: false,
      playSound: false,
      showBadge: false,
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
    final enabled = prefs.getBool(_keyStatusNotificationEnabled) ?? true;

    if (enabled) {
      await showStatusNotification();
    }
  }

  /// Démarrer les mises à jour périodiques du statut
  void _startPeriodicStatusUpdates() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(
      const Duration(minutes: 5), // Mise à jour toutes les 5 minutes
      (_) => _updateStatusNotification(),
    );
  }

  /// Mettre à jour le statut de la géolocalisation
  void updateGeolocationStatus(ServiceStatus status, {DateTime? lastUpdate}) {
    _geolocationStatus = status;
    if (lastUpdate != null) {
      _lastLocationUpdate = lastUpdate;
    }
    _updateStatusNotification();
  }

  /// Mettre à jour le statut du géofencing
  void updateGeofencingStatus(
    ServiceStatus status, {
    int dangerZones = 0,
    int safeZones = 0,
  }) {
    _geofencingStatus = status;
    _monitoredDangerZones = dangerZones;
    _monitoredSafeZones = safeZones;
    _updateStatusNotification();
  }

  /// Mettre à jour le statut de la localisation en arrière-plan
  void updateBackgroundLocationStatus(ServiceStatus status) {
    _backgroundLocationStatus = status;
    _updateStatusNotification();
  }

  /// Afficher la notification de statut
  Future<void> showStatusNotification() async {
    if (!_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyStatusNotificationEnabled) ?? true;

    if (!enabled) return;

    await _updateStatusNotification();
  }

  /// Masquer la notification de statut
  Future<void> hideStatusNotification() async {
    await _localNotifications.cancel(_statusNotificationId);
  }

  /// Mettre à jour la notification de statut
  Future<void> _updateStatusNotification() async {
    if (!_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyStatusNotificationEnabled) ?? true;

    if (!enabled) return;

    final statusText = _buildStatusText();
    final detailText = _buildDetailText();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Notification persistante
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
      icon: '@mipmap/launcher_icon', // Icône de sécurité
      color: const Color(0xFF006970), // Couleur principale de l'app
      styleInformation: BigTextStyleInformation(
        detailText,
        contentTitle: statusText,
        summaryText: 'AlertContacts - Surveillance active',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      threadIdentifier: 'service_status',
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        _statusNotificationId,
        statusText,
        detailText,
        platformDetails,
      );

      // Sauvegarder l'heure de la dernière mise à jour
      await prefs.setString(
        _keyLastStatusUpdate,
        DateTime.now().toIso8601String(),
      );

      log('PersistentStatusNotificationService: Status notification updated');
    } catch (e) {
      log(
        'PersistentStatusNotificationService: Error updating notification: $e',
      );
    }
  }

  /// Construire le texte de statut principal
  String _buildStatusText() {
    final activeServices = <String>[];
    final startingServices = <String>[];

    if (_geolocationStatus == ServiceStatus.running) {
      activeServices.add('Géolocalisation');
    } else if (_geolocationStatus == ServiceStatus.starting) {
      startingServices.add('Géolocalisation');
    }

    if (_geofencingStatus == ServiceStatus.running) {
      activeServices.add('Surveillance zones');
    } else if (_geofencingStatus == ServiceStatus.starting) {
      startingServices.add('Surveillance zones');
    }

    if (_backgroundLocationStatus == ServiceStatus.running) {
      activeServices.add('Localisation continue');
    } else if (_backgroundLocationStatus == ServiceStatus.starting) {
      startingServices.add('Localisation continue');
    }

    // Priorité à l'affichage des services en cours d'initialisation
    if (startingServices.isNotEmpty) {
      return 'Initialisation des services...';
    } else if (activeServices.isEmpty) {
      return 'Services de surveillance arrêtés';
    } else if (activeServices.length == 1) {
      return '${activeServices.first} active';
    } else {
      return '${activeServices.length} services actifs';
    }
  }

  /// Construire le texte de détail
  String _buildDetailText() {
    final details = <String>[];

    // Statut de la géolocalisation
    if (_geolocationStatus == ServiceStatus.running) {
      final lastUpdateText = _lastLocationUpdate != null
          ? _formatLastUpdate(_lastLocationUpdate!)
          : 'jamais';
      details.add(
        '📍 Géolocalisation: active (dernière mise à jour: $lastUpdateText)',
      );
    } else if (_geolocationStatus == ServiceStatus.starting) {
      details.add('📍 Géolocalisation: initialisation...');
    } else {
      details.add('📍 Géolocalisation: arrêtée');
    }

    // Statut du géofencing
    if (_geofencingStatus == ServiceStatus.running) {
      final zonesText = _monitoredDangerZones > 0 || _monitoredSafeZones > 0
          ? '${_monitoredDangerZones} zones de danger, ${_monitoredSafeZones} zones sûres'
          : 'aucune zone';
      details.add('🛡️ Surveillance: active ($zonesText)');
    } else if (_geofencingStatus == ServiceStatus.starting) {
      details.add('🛡️ Surveillance: initialisation...');
    } else {
      details.add('🛡️ Surveillance: arrêtée');
    }

    // Statut de la localisation en arrière-plan
    if (_backgroundLocationStatus == ServiceStatus.running) {
      details.add('🔄 Localisation continue: active');
    } else if (_backgroundLocationStatus == ServiceStatus.starting) {
      details.add('🔄 Localisation continue: initialisation...');
    } else {
      details.add('🔄 Localisation continue: arrêtée');
    }

    return details.join('\n');
  }

  /// Formater la dernière mise à jour
  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'il y a ${difference.inDays}j';
    }
  }

  /// Activer/désactiver les notifications de statut
  Future<void> setStatusNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStatusNotificationEnabled, enabled);

    if (enabled) {
      await showStatusNotification();
    } else {
      await hideStatusNotification();
    }

    log(
      'PersistentStatusNotificationService: Status notifications ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Vérifier si les notifications de statut sont activées
  Future<bool> isStatusNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStatusNotificationEnabled) ?? true;
  }

  /// Getters pour l'état des services
  ServiceStatus get geolocationStatus => _geolocationStatus;
  ServiceStatus get geofencingStatus => _geofencingStatus;
  ServiceStatus get backgroundLocationStatus => _backgroundLocationStatus;
  DateTime? get lastUpdate => _lastLocationUpdate;
  int get monitoredDangerZones => _monitoredDangerZones;
  int get monitoredSafeZones => _monitoredSafeZones;

  /// Vérifier si au moins un service est actif
  bool get hasActiveServices {
    return _geolocationStatus == ServiceStatus.running ||
        _geofencingStatus == ServiceStatus.running ||
        _backgroundLocationStatus == ServiceStatus.running;
  }

  /// Obtenir les statistiques des services
  Map<String, dynamic> getServiceStatistics() {
    return {
      'geolocation_status': _geolocationStatus.name,
      'geofencing_status': _geofencingStatus.name,
      'background_location_status': _backgroundLocationStatus.name,
      'monitored_danger_zones': _monitoredDangerZones,
      'monitored_safe_zones': _monitoredSafeZones,
      'last_location_update': _lastLocationUpdate?.toIso8601String(),
    };
  }

  /// Vérifier et mettre à jour l'état réel des services
  void _checkAndUpdateRealServiceStatus() {
    try {
      // Si aucun service n'a été explicitement mis à jour depuis l'initialisation,
      // on considère qu'ils sont arrêtés (pas encore activés par l'utilisateur)
      if (_geolocationStatus == ServiceStatus.starting) {
        _geolocationStatus = ServiceStatus.stopped;
      }
      if (_geofencingStatus == ServiceStatus.starting) {
        _geofencingStatus = ServiceStatus.stopped;
      }
      if (_backgroundLocationStatus == ServiceStatus.starting) {
        _backgroundLocationStatus = ServiceStatus.stopped;
      }

      // Mettre à jour la notification avec les vrais statuts
      _updateStatusNotification();

      log(
        'PersistentStatusNotificationService: Real service status checked and updated',
      );
    } catch (e) {
      log(
        'PersistentStatusNotificationService: Error checking real service status: $e',
      );
    }
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _statusUpdateTimer?.cancel();
    await hideStatusNotification();
    _isInitialized = false;
    log('PersistentStatusNotificationService: Disposed');
  }
}

/// Énumération des statuts de service
enum ServiceStatus { stopped, starting, running, error }
