import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_manager.dart';
import 'core/services/permissions_service.dart';
import 'theme/colors.dart';

class DebugFCMPage extends StatefulWidget {
  const DebugFCMPage({super.key});

  @override
  State<DebugFCMPage> createState() => _DebugFCMPageState();
}

class _DebugFCMPageState extends State<DebugFCMPage> {
  String? _fcmToken;
  String? _lastMessage;
  bool _isLoading = false;
  List<String> _logs = [];
  NotificationSettings? _notificationSettings;

  @override
  void initState() {
    super.initState();
    _initializeFCMDebug();
    _setupMessageListeners();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()}: $message');
    });
    print('FCM DEBUG: $message');
  }

  Future<void> _initializeFCMDebug() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('Initialisation du debug FCM...');
      
      // Vérifier les permissions
      final hasPermission = await PermissionsService.isNotificationPermissionGranted();
      _addLog('Permission notifications: $hasPermission');
      
      // Récupérer les paramètres de notification
      _notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
      _addLog('Statut autorisation: ${_notificationSettings?.authorizationStatus}');
      
      // Récupérer le token FCM
      _fcmToken = await FirebaseMessaging.instance.getToken();
      _addLog('Token FCM récupéré: ${_fcmToken?.substring(0, 20)}...');
      
      // Vérifier si FCMService est disponible
      try {
        final fcmService = context.read<FCMService>();
        final storedToken = await fcmService.getStoredToken();
        _addLog('Token stocké localement: ${storedToken?.substring(0, 20)}...');
      } catch (e) {
        _addLog('Erreur FCMService: $e');
      }
      
    } catch (e) {
      _addLog('Erreur initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupMessageListeners() {
    _addLog('Configuration des listeners de messages...');
    
    // Messages en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addLog('Message reçu en foreground: ${message.messageId}');
      _addLog('Titre: ${message.notification?.title}');
      _addLog('Corps: ${message.notification?.body}');
      _addLog('Data: ${message.data}');
      
      setState(() {
        _lastMessage = 'Foreground: ${message.notification?.title ?? 'Sans titre'}';
      });
    });

    // Messages quand l'app s'ouvre via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addLog('App ouverte via notification: ${message.messageId}');
      _addLog('Titre: ${message.notification?.title}');
      _addLog('Corps: ${message.notification?.body}');
      
      setState(() {
        _lastMessage = 'App ouverte: ${message.notification?.title ?? 'Sans titre'}';
      });
    });

    // Vérifier si l'app a été ouverte via une notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _addLog('App lancée via notification: ${message.messageId}');
        setState(() {
          _lastMessage = 'App lancée: ${message.notification?.title ?? 'Sans titre'}';
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('Demande de permissions...');
      final granted = await PermissionsService.requestNotificationPermission();
      _addLog('Permissions accordées: $granted');
      
      // Rafraîchir les informations
      await _initializeFCMDebug();
    } catch (e) {
      _addLog('Erreur demande permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('Rafraîchissement du token...');
      await FirebaseMessaging.instance.deleteToken();
      _fcmToken = await FirebaseMessaging.instance.getToken();
      _addLog('Nouveau token: ${_fcmToken?.substring(0, 20)}...');
      
      setState(() {});
    } catch (e) {
      _addLog('Erreur rafraîchissement token: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copié dans le presse-papiers')),
      );
    }
  }

  Future<void> _testLocalNotification() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('Test de notification locale...');
      
      // Utiliser le NotificationManager pour tester
      final notificationManager = NotificationManager();
      
      // Initialiser si nécessaire
      await notificationManager.initialize();
      
      // Tester une alerte de zone de danger (notification + vibration + voix)
      await notificationManager.triggerDangerZoneAlert(
        zoneName: 'Zone de Test Debug',
        distanceMeters: 50,
        severity: 'high',
      );
      
      _addLog('Notification de test envoyée avec succès');
      
      setState(() {
        _lastMessage = 'Test: ⚠️ Zone de danger détectée - Zone de Test Debug (50m)';
      });
      
    } catch (e) {
      _addLog('Erreur test notification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations générales
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations FCM',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Statut autorisation: ${_notificationSettings?.authorizationStatus ?? 'Inconnu'}'),
                          const SizedBox(height: 4),
                          Text('Dernier message: ${_lastMessage ?? 'Aucun'}'),
                          const SizedBox(height: 8),
                          if (_fcmToken != null) ...[
                            Text('Token FCM:', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _fcmToken!,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _requestPermissions,
                                  child: const Text('Demander permissions'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _refreshToken,
                                  child: const Text('Rafraîchir token'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _fcmToken != null ? _copyToken : null,
                              child: const Text('Copier token'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _testLocalNotification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading 
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('🚨 Tester Notification Push'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logs
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Logs (${_logs.length})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () => setState(() => _logs.clear()),
                                child: const Text('Effacer'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 300,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    _logs[index],
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}