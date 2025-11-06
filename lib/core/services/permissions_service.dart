import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionsService {
  static const String _locationPermissionKey = 'location_permission_granted';
  static const String _notificationPermissionKey = 'notification_permission_granted';
  static const String _permissionsSetupCompleteKey = 'permissions_setup_complete';

  /// Vérifie si l'utilisateur a déjà configuré ses permissions
  static Future<bool> isPermissionsSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsSetupCompleteKey) ?? false;
  }

  /// Marque la configuration des permissions comme terminée
  static Future<void> markPermissionsSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsSetupCompleteKey, true);
  }

  /// Demande la permission de géolocalisation
  static Future<bool> requestLocationPermission() async {
    try {
      // Vérifier d'abord si les services de localisation sont activés
      bool serviceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        // Les services de localisation ne sont pas activés
        return false;
      }

      // Demander la permission
      PermissionStatus permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        permission = await Permission.locationWhenInUse.request();
        if (permission.isDenied) {
          return false;
        }
      }

      if (permission.isPermanentlyDenied) {
        // Les permissions sont refusées de façon permanente
        return false;
      }

      // Permission accordée
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Demande la permission pour les notifications
  static Future<bool> requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Demander la permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                       settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isGranted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationPermissionKey, true);
      }

      return isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie le statut actuel de la permission de géolocalisation
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Permission.locationWhenInUse.status;
      return permission.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie le statut actuel de la permission de géolocalisation en arrière-plan
  static Future<bool> isBackgroundLocationPermissionGranted() async {
    try {
      final permission = await Permission.locationAlways.status;
      return permission.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie le statut actuel de la permission de notifications
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Ouvre les paramètres de l'application
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Vérifie si toutes les permissions critiques sont accordées
  static Future<bool> areAllCriticalPermissionsGranted() async {
    final locationGranted = await isLocationPermissionGranted();
    final notificationGranted = await isNotificationPermissionGranted();
    final backgroundLocationGranted = await isBackgroundLocationPermissionGranted();
    return locationGranted && notificationGranted && backgroundLocationGranted;
  }

  /// Réinitialise l'état des permissions (pour les tests)
  static Future<void> resetPermissionsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationPermissionKey);
    await prefs.remove(_notificationPermissionKey);
    await prefs.remove(_permissionsSetupCompleteKey);
  }
}