import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/services/permissions_service.dart';

class DebugPermissionsPage extends StatefulWidget {
  const DebugPermissionsPage({Key? key}) : super(key: key);

  @override
  State<DebugPermissionsPage> createState() => _DebugPermissionsPageState();
}

class _DebugPermissionsPageState extends State<DebugPermissionsPage> {
  String _status = 'Vérification en cours...';
  String _fcmToken = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Vérifier les permissions via permission_handler
      final notificationStatus = await Permission.notification.status;
      
      // Vérifier les permissions via Firebase
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      
      // Récupérer le token FCM
      final token = await messaging.getToken();
      
      // Vérifier via PermissionsService
      final serviceCheck = await PermissionsService.isNotificationPermissionGranted();
      
      setState(() {
        _status = '''
Permission Handler Status: ${notificationStatus.name}
Firebase Authorization: ${settings.authorizationStatus.name}
Firebase Alert Setting: ${settings.alert.name}
Firebase Badge Setting: ${settings.badge.name}
Firebase Sound Setting: ${settings.sound.name}
PermissionsService Check: $serviceCheck
        ''';
        _fcmToken = token ?? 'Aucun token';
      });
      
      print('🔔 DEBUG PERMISSIONS:');
      print('Permission Handler: ${notificationStatus.name}');
      print('Firebase Auth: ${settings.authorizationStatus.name}');
      print('Firebase Alert: ${settings.alert.name}');
      print('Firebase Badge: ${settings.badge.name}');
      print('Firebase Sound: ${settings.sound.name}');
      print('Service Check: $serviceCheck');
      print('FCM Token: ${token?.substring(0, 20)}...');
      
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
      print('❌ Erreur lors de la vérification des permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Demander via permission_handler
      final status = await Permission.notification.request();
      
      // Demander via Firebase
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('🔔 APRÈS DEMANDE:');
      print('Permission Handler: ${status.name}');
      print('Firebase Auth: ${settings.authorizationStatus.name}');
      
      // Re-vérifier
      await _checkPermissions();
      
    } catch (e) {
      print('❌ Erreur lors de la demande de permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Permissions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut des permissions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 24),
            const Text(
              'Token FCM:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(_fcmToken),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('Demander les permissions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Re-vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}