import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'api_auth_service.dart';
import 'prefs_service.dart';

/// Service pour gérer les tokens FCM (Firebase Cloud Messaging)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenSentKey = 'fcm_token_sent';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;
  String? _bearerToken;
  String? _baseUrl;

  /// Initialiser le service FCM
  Future<void> initialize({
    required String baseUrl,
    String? bearerToken,
  }) async {
    try {
      log('FCMService: Initializing...');
      _baseUrl = baseUrl;
      _bearerToken = bearerToken;

      // Demander la permission pour les notifications
      await _requestPermission();

      // Récupérer le token FCM
      await _getToken();

      debugPrint('FCMService: Current token: $_currentToken');

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Configurer les handlers de messages FCM
      _setupMessageHandlers();

      log('FCMService: Initialized successfully');
    } catch (e) {
      log('FCMService: Error during initialization: $e');
    }
  }

  /// Demander la permission pour les notifications
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('FCMService: Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('FCMService: Error requesting permission: $e');
    }
  }

  /// Récupérer le token FCM
  Future<String?> _getToken() async {
    try {
      log('🔥 FCMService._getToken: DÉBUT');

      final token = await _messaging.getToken();
      if (token != null) {
        log(
          '🔥 FCMService._getToken: Token récupéré: ${token.substring(0, 20)}...',
        );
        _currentToken = token;
        await _saveTokenLocally(token);

        // Envoyer au backend si on a les credentials
        if (_bearerToken != null && _baseUrl != null) {
          log('🔥 FCMService._getToken: Envoi du token au backend...');
          final success = await _sendTokenToBackend(token);
          log(
            '🔥 FCMService._getToken: Envoi ${success ? "RÉUSSI" : "ÉCHOUÉ"}',
          );
        } else {
          log('⚠️ FCMService._getToken: Pas d\'envoi - credentials manquants');
          log(
            '⚠️ FCMService._getToken: _bearerToken: ${_bearerToken != null ? "OK" : "NULL"}',
          );
          log(
            '⚠️ FCMService._getToken: _baseUrl: ${_baseUrl != null ? "OK" : "NULL"}',
          );
        }
      } else {
        log('❌ FCMService._getToken: Impossible de récupérer le token');
      }

      log('🔥 FCMService._getToken: FIN');
      return token;
    } catch (e) {
      log('❌ FCMService._getToken: Erreur: $e');
      return null;
    }
  }

  /// Gérer le rafraîchissement du token
  Future<void> _onTokenRefresh(String token) async {
    try {
      log('FCMService: Token refreshed: ${token.substring(0, 20)}...');
      _currentToken = token;
      await _saveTokenLocally(token);

      // Envoyer le nouveau token au backend
      if (_bearerToken != null && _baseUrl != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      log('FCMService: Error handling token refresh: $e');
    }
  }

  /// Sauvegarder le token localement
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      log('FCMService: Token saved locally');
    } catch (e) {
      log('FCMService: Error saving token locally: $e');
    }
  }

  /// Récupérer le token sauvegardé localement
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      log('FCMService: Error getting stored token: $e');
      return null;
    }
  }

  /// Envoyer le token au backend
  Future<bool> _sendTokenToBackend(
    String token, {
    bool forceUpdate = false,
  }) async {
    log('🔥 FCMService._sendTokenToBackend: DÉBUT');
    log(
      '🔥 FCMService._sendTokenToBackend: Token: ${token.substring(0, 20)}...',
    );
    log('🔥 FCMService._sendTokenToBackend: _baseUrl: $_baseUrl');
    log(
      '🔥 FCMService._sendTokenToBackend: _bearerToken: ${_bearerToken?.substring(0, 10)}...',
    );
    log('🔥 FCMService._sendTokenToBackend: forceUpdate: $forceUpdate');

    if (_baseUrl == null || _bearerToken == null) {
      log('❌ FCMService._sendTokenToBackend: Credentials manquants');
      log(
        '❌ FCMService._sendTokenToBackend: _baseUrl null: ${_baseUrl == null}',
      );
      log(
        '❌ FCMService._sendTokenToBackend: _bearerToken null: ${_bearerToken == null}',
      );
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSentToken = prefs.getString(_fcmTokenSentKey);

      // Ne pas renvoyer le même token sauf si forceUpdate est true
      if (lastSentToken == token && !forceUpdate) {
        log(
          'ℹ️ FCMService._sendTokenToBackend: Token déjà envoyé (pas de forceUpdate)',
        );
        return true;
      }

      if (forceUpdate) {
        log(
          '🔄 FCMService._sendTokenToBackend: Envoi forcé du token (nouvelle connexion)',
        );
      }

      // Récupérer l'email de l'utilisateur
      final prefsService = PrefsService();
      final userProfile = await prefsService.getUserProfile();

      if (userProfile?.email == null) {
        log(
          '❌ FCMService._sendTokenToBackend: Email utilisateur non disponible',
        );
        return false;
      }

      // Utiliser ApiAuthService pour envoyer le token via la route publique
      log(
        '🔥 FCMService._sendTokenToBackend: Utilisation d\'ApiAuthService (route publique)',
      );
      final apiAuthService = ApiAuthService(baseUrl: _baseUrl!);

      final platform = Platform.isAndroid ? 'android' : 'ios';
      log('🔥 FCMService._sendTokenToBackend: Platform: $platform');
      log('🔥 FCMService._sendTokenToBackend: Email: ${userProfile!.email}');

      // Utiliser la nouvelle méthode publique avec l'ancien token pour plus de sécurité
      await apiAuthService.sendFcmToken(
        token,
        platform,
        userProfile.email,
        oldFcmToken: lastSentToken,
      );

      // Sauvegarder le token envoyé pour éviter les doublons
      await prefs.setString(_fcmTokenSentKey, token);
      log(
        '✅ FCMService._sendTokenToBackend: Token envoyé avec succès via route publique',
      );
      return true;
    } catch (e) {
      log('❌ FCMService._sendTokenToBackend: Exception: $e');
      return false;
    }
  }

  /// Initialiser le service FCM après connexion
  Future<void> initializeAfterLogin() async {
    try {
      log('🔥 FCMService.initializeAfterLogin: DÉBUT');
      log('🔥 FCMService.initializeAfterLogin: _baseUrl = $_baseUrl');
      log(
        '🔥 FCMService.initializeAfterLogin: _bearerToken = ${_bearerToken?.substring(0, 10)}...',
      );

      // Demander la permission pour les notifications
      await _requestPermission();

      // Récupérer et envoyer le token FCM avec force update pour nouvelle connexion
      await _getTokenWithForceUpdate();

      log('🔥 FCMService.initializeAfterLogin: FIN');
    } catch (e) {
      log('❌ FCMService.initializeAfterLogin: Erreur: $e');
      // Ne pas faire échouer la connexion pour un problème FCM
    }
  }

  /// Récupérer le token FCM et forcer l'envoi au backend (pour nouvelles connexions)
  Future<String?> _getTokenWithForceUpdate() async {
    try {
      log('🔥 FCMService._getTokenWithForceUpdate: DÉBUT');

      final token = await _messaging.getToken();
      if (token != null) {
        log(
          '🔥 FCMService._getTokenWithForceUpdate: Token récupéré: ${token.substring(0, 20)}...',
        );
        _currentToken = token;
        await _saveTokenLocally(token);

        // Forcer l'envoi au backend même si le token a déjà été envoyé
        if (_bearerToken != null && _baseUrl != null) {
          log(
            '🔥 FCMService._getTokenWithForceUpdate: Envoi forcé du token au backend...',
          );
          final success = await _sendTokenToBackend(token, forceUpdate: true);
          log(
            '🔥 FCMService._getTokenWithForceUpdate: Envoi ${success ? "RÉUSSI" : "ÉCHOUÉ"}',
          );
        } else {
          log(
            '⚠️ FCMService._getTokenWithForceUpdate: Pas d\'envoi - credentials manquants',
          );
        }
      } else {
        log(
          '❌ FCMService._getTokenWithForceUpdate: Impossible de récupérer le token',
        );
      }

      log('🔥 FCMService._getTokenWithForceUpdate: FIN');
      return token;
    } catch (e) {
      log('❌ FCMService._getTokenWithForceUpdate: Erreur: $e');
      return null;
    }
  }

  /// Forcer l'envoi du token FCM au backend (méthode publique)
  Future<bool> forceSendTokenToBackend() async {
    try {
      log('🔥 FCMService.forceSendTokenToBackend: DÉBUT');

      if (_currentToken == null) {
        log('⚠️ FCMService.forceSendTokenToBackend: Aucun token disponible');
        return false;
      }

      final success = await _sendTokenToBackend(
        _currentToken!,
        forceUpdate: true,
      );
      log(
        '🔥 FCMService.forceSendTokenToBackend: Résultat: ${success ? "SUCCÈS" : "ÉCHEC"}',
      );

      return success;
    } catch (e) {
      log('❌ FCMService.forceSendTokenToBackend: Erreur: $e');
      return false;
    }
  }

  /// Vérifier si le service est configuré
  bool get isConfigured => _baseUrl != null && _bearerToken != null;

  /// Configurer les handlers de messages FCM
  void _setupMessageHandlers() {
    try {
      log('FCMService: Setting up message handlers...');

      // Handler pour les messages reçus quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handler pour les interactions avec les notifications
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Note: Le handler de background est configuré dans main.dart
      log('FCMService: Message handlers configured successfully');
    } catch (e) {
      log('FCMService: Error setting up message handlers: $e');
    }
  }

  /// Traiter les messages reçus au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      log('FCMService: ========== FOREGROUND MESSAGE RECEIVED ==========');
      log('FCMService: Message ID: ${message.messageId}');
      log('FCMService: Notification title: ${message.notification?.title}');
      log('FCMService: Notification body: ${message.notification?.body}');
      log('FCMService: Data: ${message.data}');
      log('FCMService: From: ${message.from}');
      log('FCMService: ================================================');

      await _processNotificationMessage(message);
    } catch (e) {
      log('FCMService: Error handling foreground message: $e');
    }
  }

  /// Méthode publique pour traiter les messages en arrière-plan (appelée depuis main.dart)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _handleBackgroundMessage(message);
  }

  /// Traiter les messages reçus en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      log('FCMService: Received background message: ${message.messageId}');
      // Pour les messages en arrière-plan, on traite via le NotificationManager
      final notificationManager = NotificationManager();
      await notificationManager.initialize();
      await _processNotificationMessageStatic(message, notificationManager);
    } catch (e) {
      log('FCMService: Error handling background message: $e');
    }
  }

  /// Traiter l'interaction avec une notification
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      log('FCMService: Notification tapped: ${message.messageId}');
      // Ici on pourrait naviguer vers une page spécifique selon le type de notification
      await _processNotificationMessage(message);
    } catch (e) {
      log('FCMService: Error handling notification tap: $e');
    }
  }

  /// Traiter le message de notification et déclencher les alertes appropriées
  Future<void> _processNotificationMessage(RemoteMessage message) async {
    try {
      final notificationManager = NotificationManager();
      await notificationManager.initialize();
      await _processNotificationMessageStatic(message, notificationManager);
    } catch (e) {
      log('FCMService: Error processing notification message: $e');
    }
  }

  /// Version statique pour traiter les messages (utilisée en arrière-plan)
  static Future<void> _processNotificationMessageStatic(
    RemoteMessage message,
    NotificationManager notificationManager,
  ) async {
    try {
      final data = message.data;
      final notification = message.notification;

      log('FCMService: ========== PROCESSING NOTIFICATION ==========');
      log('FCMService: Type: ${data['type']}');
      log('FCMService: Title: ${notification?.title}');
      log('FCMService: Body: ${notification?.body}');
      log('FCMService: Data keys: ${data.keys.toList()}');
      log(
        'FCMService: NotificationManager initialized: ${notificationManager.isInitialized}',
      );
      log('FCMService: ============================================');

      // Traiter selon le type de notification
      switch (data['type']) {
        case 'danger_zone_alert':
          log('FCMService: Handling danger zone alert...');
          await _handleDangerZoneAlert(data, notification, notificationManager);
          break;
        case 'safe_zone_exit':
        case 'safe_zone_exit_reminder':
          log('FCMService: Handling safe zone alert...');
          await _handleSafeZoneAlert(data, notification, notificationManager);
          break;
        case 'invitation_response':
          log('FCMService: Handling invitation response...');
          await _handleInvitationResponse(
            data,
            notification,
            notificationManager,
          );
          break;
      }

      log('FCMService: Notification processing completed');
    } catch (e) {
      log('FCMService: Error in _processNotificationMessageStatic: $e');
    }
  }

  /// Traiter une alerte de zone de danger
  static Future<void> _handleDangerZoneAlert(
    Map<String, dynamic> data,
    RemoteNotification? notification,
    NotificationManager notificationManager,
  ) async {
    try {
      log('FCMService: ========== DANGER ZONE ALERT HANDLER ==========');
      log('FCMService: Raw data received: $data');
      log('FCMService: Data type: ${data.runtimeType}');
      log('FCMService: All data keys and values:');
      data.forEach((key, value) {
        log('FCMService:   $key: $value (${value.runtimeType})');
      });
      log('FCMService: zone_name key exists: ${data.containsKey('zone_name')}');
      log('FCMService: zone_name value: ${data['zone_name']}');
      log('FCMService: zone_name is null: ${data['zone_name'] == null}');
      log('FCMService: zone_name is empty: ${data['zone_name'] == ''}');

      // Vérifier que zone_name est valide
      final zoneName = data['zone_name']?.toString().trim();
      if (zoneName == null || zoneName.isEmpty) {
        log('FCMService: ⚠️ ALERTE IGNORÉE - zone_name manquant ou vide');
        log('FCMService: Données reçues: $data');
        log(
          'FCMService: Cette alerte sera ignorée pour éviter les alertes "Zone inconnue"',
        );
        log('FCMService: ===============================================');
        return;
      }

      log('FCMService: Final zoneName: $zoneName');
      final severity = data['severity'] ?? 'medium';
      final distanceMeters =
          (double.tryParse(data['distance']?.toString() ?? '0') ?? 0.0).round();

      log('FCMService: Zone: $zoneName');
      log('FCMService: Severity: $severity');
      log('FCMService: Distance: ${distanceMeters}m');
      log(
        'FCMService: NotificationManager ready: ${notificationManager.isInitialized}',
      );

      log('FCMService: Calling triggerDangerZoneAlert...');
      await notificationManager.triggerDangerZoneAlert(
        zoneName: zoneName,
        severity: severity,
        distanceMeters: distanceMeters,
      );

      log('FCMService: triggerDangerZoneAlert completed successfully');
      log('FCMService: ===============================================');
    } catch (e) {
      log('FCMService: Error handling danger zone alert: $e');
    }
  }

  /// Traiter une alerte de zone de sécurité
  static Future<void> _handleSafeZoneAlert(
    Map<String, dynamic> data,
    RemoteNotification? notification,
    NotificationManager notificationManager,
  ) async {
    try {
      // Vérifier que zone_name est valide
      final zoneName = data['zone_name']?.toString().trim();
      if (zoneName == null || zoneName.isEmpty) {
        log(
          'FCMService: ⚠️ ALERTE ZONE SÉCURITÉ IGNORÉE - zone_name manquant ou vide',
        );
        log('FCMService: Données reçues: $data');
        return;
      }

      final type = data['type'] ?? 'safe_zone_exit';
      final contactName = data['assigned_user_name'] ?? 'Contact';

      // Ne traiter que les sorties de zone
      if (type != 'safe_zone_exit') {
        log('FCMService: Ignoring safe zone entry notification');
        return;
      }

      log('FCMService: Handling safe zone exit alert - Zone: $zoneName');

      await notificationManager.triggerSafeZoneExitAlert(
        zoneName: zoneName,
        contactName: contactName,
      );
    } catch (e) {
      log('FCMService: Error handling safe zone alert: $e');
    }
  }

  /// Traiter une notification générale

  /// Gérer les notifications de réponse d'invitation
  static Future<void> _handleInvitationResponse(
    Map<String, dynamic> data,
    RemoteNotification? notification,
    NotificationManager notificationManager,
  ) async {
    try {
      log('FCMService: Processing invitation response notification...');

      // Afficher la notification avec un payload spécial pour la navigation
      await notificationManager.sendSimpleNotification(
        title: notification?.title ?? 'Réponse d\'invitation',
        body: notification?.body ?? 'Un proche a répondu à votre invitation',
        payload: jsonEncode({
          ...data,
          'navigate_to': 'proches', // Indique où naviguer
        }),
      );

      log(
        'FCMService: Invitation response notification displayed successfully',
      );
    } catch (e) {
      log('FCMService: Error handling invitation response notification: $e');
    }
  }

  /// Obtenir le token actuel (getter)
  String? get currentToken => _currentToken;

  /// Mettre à jour les credentials (baseUrl et bearerToken)
  void updateCredentials({String? baseUrl, String? bearerToken}) {
    log('🔥 FCMService.updateCredentials: DÉBUT');
    log('🔥 FCMService.updateCredentials: baseUrl = $baseUrl');
    log(
      '🔥 FCMService.updateCredentials: bearerToken = ${bearerToken?.substring(0, 10)}...',
    );

    if (baseUrl != null) {
      _baseUrl = baseUrl;
      log('🔥 FCMService.updateCredentials: _baseUrl mis à jour');
    }
    if (bearerToken != null) {
      _bearerToken = bearerToken;
      log('🔥 FCMService.updateCredentials: _bearerToken mis à jour');
    }

    log('🔥 FCMService.updateCredentials: FIN');
  }
}
