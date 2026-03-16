import 'dart:async';

import 'package:alertcontacts/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/pending_deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Handler global pour les messages FCM en arrière-plan
/// DOIT être une fonction top-level pour Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase uniquement s'il n'a pas déjà été fait
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Déléguer le traitement au
  await FCMService.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await PendingDeepLinkService.cleanupExpiredTokens();

  if (kReleaseMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runZonedGuarded(
    () {
      runApp(const AlertContactApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
