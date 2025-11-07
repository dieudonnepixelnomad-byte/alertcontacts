import 'package:alertcontacts/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/pending_deep_link_service.dart';
import 'core/services/fcm_service.dart';

/// Handler global pour les messages FCM en arrière-plan
/// DOIT être une fonction top-level pour Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase uniquement s'il n'a pas déjà été fait
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Déléguer le traitement au FCMService
  await FCMService.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Configurer le handler de background message au niveau global
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Nettoyer les tokens expirés au démarrage
  await PendingDeepLinkService.cleanupExpiredTokens();

  runApp(const AlertContactApp());
}
