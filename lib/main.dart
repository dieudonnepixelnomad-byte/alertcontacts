import 'dart:async';
import 'dart:io';

import 'package:alertcontacts/firebase_options.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/pending_deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/revenuecat_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Handler headless pour background_fetch (Android app terminée)
@pragma('vm:entry-point')
void _backgroundFetchHeadlessTask(HeadlessTask task) {
  // App terminée sur Android — pas de services dispo, on termine immédiatement.
  // La position sera récupérée au prochain démarrage via LocationService.
  BackgroundFetch.finish(task.taskId);
}

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
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
      }

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      }

      runApp(const AlertContactApp());

      // Enregistrer le handler headless background_fetch (Android uniquement)
      BackgroundFetch.registerHeadlessTask(_backgroundFetchHeadlessTask);

      // Deferred after first frame — avoid blocking UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RevenueCatService.instance.configure();
        PendingDeepLinkService.cleanupExpiredTokens();
        if (Platform.isIOS) {
          AppTrackingTransparency.trackingAuthorizationStatus.then((status) {
            if (status == TrackingStatus.notDetermined) {
              AppTrackingTransparency.requestTrackingAuthorization();
            }
          });
        }
      });
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
