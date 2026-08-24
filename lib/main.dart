import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alertcontacts/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/services/pending_deep_link_service.dart';
import 'core/services/app_review_service.dart';
import 'core/services/fcm_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Handler headless pour background_fetch — s'exécute quand l'app Android est fermée.
/// Récupère la position GPS et la publie sur Firebase RTDB + Laravel API
/// pour que la détection de zone du backend continue de fonctionner.
@pragma('vm:entry-point')
void _backgroundFetchHeadlessEvent(HeadlessEvent task) {
  _runHeadlessLocationUpdate(task);
}

Future<void> _runHeadlessLocationUpdate(HeadlessEvent task) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final uid =
        prefs.getString('flutter.firebase_uid') ??
        prefs.getString('firebase_uid');
    final bearerToken =
        prefs.getString('flutter.bearer_token') ??
        prefs.getString('bearer_token');

    if (uid == null) {
      BackgroundFetch.finish(task.taskId);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    ).timeout(const Duration(seconds: 10));

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Publier sur Firebase RTDB pour que les proches voient la position
    await FirebaseDatabase.instance.ref('locations/$uid').update({
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'updated_at': timestamp,
      'is_invisible': false,
    });

    // Envoyer au backend Laravel pour déclencher la détection de zone
    if (bearerToken != null) {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/locations/batch'),
            headers: {
              'Authorization': 'Bearer $bearerToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'locations': [
                {
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'accuracy': position.accuracy,
                  'timestamp': timestamp,
                  'foreground': false,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));
    }
  } catch (_) {
    // Silencieux — on ne peut pas loguer sans Crashlytics initialisé en mode headless
  } finally {
    BackgroundFetch.finish(task.taskId);
  }
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
      await dotenv.load(fileName: '.env');
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

      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        AppReviewService().recordRecentError();
      };

      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          false,
        );
      }

      runApp(const AlertContactApp());
      await AppReviewService().initialize();

      // Enregistrer le handler headless background_fetch (Android uniquement)
      BackgroundFetch.registerHeadlessTask(_backgroundFetchHeadlessEvent);

      // Deferred after first frame — avoid blocking UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      AppReviewService().recordRecentError();
    },
  );
}
