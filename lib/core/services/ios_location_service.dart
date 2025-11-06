import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_point.dart';
import 'batch_sender_service.dart';

/// Service pour gérer la communication avec le service iOS natif de géolocalisation
class IOSLocationService {
  static final IOSLocationService _instance = IOSLocationService._internal();
  factory IOSLocationService() => _instance;
  IOSLocationService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.alertcontacts/geofencing',
  );
  static const MethodChannel _locationUpdatesChannel = MethodChannel(
    'com.alertcontacts/location_updates',
  );
  static const String _serviceEnabledKey = 'ios_location_service_enabled';

  bool _isServiceRunning = false;
  final BatchSenderService _batchSender = BatchSenderService();

  /// Getter pour savoir si le service natif est en cours d'exécution
  bool get isServiceRunning => _isServiceRunning;

  /// Initialise le service iOS
  Future<void> initialize() async {
    try {
      dev.log('IOSLocationService: Initialisation du service');

      // Configurer les listeners pour les mises à jour de localisation
      _locationUpdatesChannel.setMethodCallHandler(_handleLocationUpdates);

      // Charger l'état précédent
      final wasEnabled = await loadServiceState();

      if (wasEnabled) {
        dev.log('IOSLocationService: Redémarrage automatique du service');
        await startBackgroundLocation();
      }

      dev.log('IOSLocationService: Initialisation terminée');
    } catch (e) {
      dev.log('IOSLocationService: Erreur lors de l\'initialisation: $e');
    }
  }

  /// Démarre la géolocalisation en arrière-plan iOS
  Future<bool> startBackgroundLocation() async {
    try {
      dev.log(
        'IOSLocationService: Démarrage de la géolocalisation en arrière-plan iOS',
      );

      final result = await _channel.invokeMethod('startBackgroundLocation');

      if (result == true) {
        _isServiceRunning = true;
        await _saveServiceState(true);
        dev.log(
          'IOSLocationService: Géolocalisation en arrière-plan démarrée avec succès',
        );
        return true;
      } else {
        dev.log(
          'IOSLocationService: Échec du démarrage de la géolocalisation en arrière-plan',
        );
        return false;
      }
    } on PlatformException catch (e) {
      dev.log(
        'IOSLocationService: Erreur plateforme lors du démarrage: ${e.message}',
      );
      return false;
    } catch (e) {
      dev.log('IOSLocationService: Erreur inattendue lors du démarrage: $e');
      return false;
    }
  }

  /// Arrête la géolocalisation en arrière-plan iOS
  Future<bool> stopBackgroundLocation() async {
    try {
      dev.log(
        'IOSLocationService: Arrêt de la géolocalisation en arrière-plan iOS',
      );

      final result = await _channel.invokeMethod('stopBackgroundLocation');

      if (result == true) {
        _isServiceRunning = false;
        await _saveServiceState(false);
        dev.log(
          'IOSLocationService: Géolocalisation en arrière-plan arrêtée avec succès',
        );
        return true;
      } else {
        dev.log(
          'IOSLocationService: Échec de l\'arrêt de la géolocalisation en arrière-plan',
        );
        return false;
      }
    } on PlatformException catch (e) {
      dev.log(
        'IOSLocationService: Erreur plateforme lors de l\'arrêt: ${e.message}',
      );
      return false;
    } catch (e) {
      dev.log('IOSLocationService: Erreur inattendue lors de l\'arrêt: $e');
      return false;
    }
  }

  /// Demande les permissions de localisation
  Future<String> requestLocationPermissions() async {
    try {
      dev.log('IOSLocationService: Demande des permissions de localisation');

      final result = await _channel.invokeMethod('requestLocationPermissions');
      dev.log('IOSLocationService: Statut des permissions: $result');

      return result as String;
    } on PlatformException catch (e) {
      dev.log('IOSLocationService: Erreur demande permissions: ${e.message}');
      return 'error';
    } catch (e) {
      dev.log('IOSLocationService: Erreur inattendue demande permissions: $e');
      return 'error';
    }
  }

  /// Vérifie si la géolocalisation en arrière-plan est activée
  Future<bool> isBackgroundLocationEnabled() async {
    try {
      final result = await _channel.invokeMethod('isBackgroundLocationEnabled');
      return result as bool;
    } on PlatformException catch (e) {
      dev.log('IOSLocationService: Erreur vérification état: ${e.message}');
      return false;
    } catch (e) {
      dev.log('IOSLocationService: Erreur inattendue vérification état: $e');
      return false;
    }
  }

  /// Sauvegarde l'état du service dans les préférences partagées
  Future<void> _saveServiceState(bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_serviceEnabledKey, isEnabled);
      dev.log('IOSLocationService: État du service sauvegardé: $isEnabled');
    } catch (e) {
      dev.log('IOSLocationService: Erreur sauvegarde état: $e');
    }
  }

  /// Charge l'état du service depuis les préférences partagées
  Future<bool> loadServiceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_serviceEnabledKey) ?? false;
      _isServiceRunning = isEnabled;
      dev.log('IOSLocationService: État du service chargé: $isEnabled');
      return isEnabled;
    } catch (e) {
      dev.log('IOSLocationService: Erreur chargement état: $e');
      return false;
    }
  }

  /// Vérifie si le service natif est disponible (iOS uniquement)
  Future<bool> isNativeServiceAvailable() async {
    try {
      // Tenter un appel simple pour vérifier la disponibilité
      await _channel.invokeMethod('isBackgroundLocationEnabled');
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'UNAVAILABLE') {
        return false;
      }
      // Si c'est une autre erreur, le service est probablement disponible
      return true;
    } catch (e) {
      // Sur Android ou autres plateformes, le service n'est pas disponible
      return false;
    }
  }

  /// Active ou désactive le service selon l'état demandé
  Future<bool> setServiceEnabled(bool enabled) async {
    if (enabled) {
      return await startBackgroundLocation();
    } else {
      return await stopBackgroundLocation();
    }
  }

  /// Obtient l'état actuel du service
  Future<Map<String, dynamic>> getServiceStatus() async {
    final isAvailable = await isNativeServiceAvailable();
    final savedState = await loadServiceState();
    final isEnabled = await isBackgroundLocationEnabled();

    return {
      'available': isAvailable,
      'running': _isServiceRunning,
      'saved_state': savedState,
      'native_enabled': isEnabled,
      'platform_supported': true, // iOS uniquement pour l'instant
    };
  }

  /// Gestionnaire des mises à jour de localisation depuis iOS
  Future<void> _handleLocationUpdates(MethodCall call) async {
    switch (call.method) {
      case 'onLocationUpdate':
        final locationData = call.arguments as Map<String, dynamic>;
        dev.log(
          'IOSLocationService: Mise à jour de localisation reçue: ${locationData['latitude']}, ${locationData['longitude']}',
        );

        // Créer un LocationPoint et l'envoyer au BatchSenderService
        try {
          final locationPoint = LocationPoint(
            latitude: (locationData['latitude'] as num).toDouble(),
            longitude: (locationData['longitude'] as num).toDouble(),
            accuracy: (locationData['accuracy'] as num?)?.toDouble() ?? 0.0,
            speed: (locationData['speed'] as num?)?.toDouble() ?? 0.0,
            heading: (locationData['heading'] as num?)?.toDouble() ?? 0.0,
            capturedAtDevice: DateTime.fromMillisecondsSinceEpoch(
              (locationData['timestamp'] as num).toInt(),
            ),
            source: 'ios_native',
            foreground: false, // Toujours en arrière-plan pour le service natif
          );

          _batchSender.addLocationPoint(locationPoint);
          dev.log(
            'IOSLocationService: Position transmise au BatchSenderService: ${locationPoint.latitude}, ${locationPoint.longitude}',
          );
        } catch (e) {
          dev.log('IOSLocationService: Erreur création LocationPoint: $e');
        }
        break;

      case 'onLocationError':
        final error = call.arguments as String;
        dev.log('IOSLocationService: Erreur de localisation: $error');
        break;

      case 'onAuthorizationChanged':
        final status = call.arguments as String;
        dev.log('IOSLocationService: Changement d\'autorisation: $status');

        // Si les permissions ont été révoquées, arrêter le service
        if (status != 'always' && _isServiceRunning) {
          await stopBackgroundLocation();
        }
        break;

      default:
        dev.log('IOSLocationService: Méthode non gérée: ${call.method}');
    }
  }
}
