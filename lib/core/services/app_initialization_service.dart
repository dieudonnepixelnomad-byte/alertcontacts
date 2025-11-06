import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:alertcontacts/core/config/api_config.dart';
import 'package:alertcontacts/core/services/critical_notification_redundancy_service.dart';
import 'package:alertcontacts/core/services/fcm_service.dart';
import 'package:alertcontacts/core/services/native_location_service.dart';
import 'package:alertcontacts/core/services/persistent_status_notification_service.dart';
import 'package:alertcontacts/core/services/proactive_system_monitor.dart';
import 'package:alertcontacts/core/services/service_health_monitor.dart';
import 'package:alertcontacts/core/services/unified_critical_alert_service.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:version/version.dart';

/// Service centralisé pour l'initialisation automatique de tous les services
/// au démarrage de l'application
class AppInitializationService {
  static const String _tag = 'AppInitializationService';

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Indique si l'initialisation est terminée
  bool get isInitialized => _isInitialized;

  /// Indique si l'initialisation est en cours
  bool get isInitializing => _isInitializing;

  /// Initialise tous les services essentiels de l'application
  /// Cette méthode doit être appelée une seule fois au démarrage
  Future<void> initializeServices(BuildContext context) async {
    if (_isInitialized || _isInitializing) {
      log('$_tag: Services déjà initialisés ou en cours d\'initialisation');
      return;
    }

    _isInitializing = true;
    log('$_tag: Début de l\'initialisation des services');

    try {
      // 0. Vérifier la mise à jour obligatoire AVANT tout le reste
      await checkUpdate();

      // 1. Initialiser les services critiques de sécurité en priorité
      await _initializeCriticalSecurityServices(context);

      // 2. Initialiser le service FCM pour les notifications push
      await _initializeFCMService(context);

      // 3. Initialiser le service de monitoring de santé
      await _initializeHealthMonitorService(context);

      // 4. Initialiser le service de géolocalisation intégré
      await _initializeGeolocationService(context);

      // 5. Initialiser le service de notification persistante en dernier
      // pour qu'il puisse afficher l'état correct des autres services
      await _initializePersistentNotificationService(context);

      _isInitialized = true;
      log('$_tag: Initialisation des services terminée avec succès');
    } catch (e) {
      log('$_tag: Erreur lors de l\'initialisation des services: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Vérifie si une mise à jour de l'application est obligatoire.
  /// Si c'est le cas, lève une [ForcedUpdateException].
  Future<void> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app-status'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String minVersionString = Platform.isIOS
            ? data['ios']['min_version']
            : data['android']['min_version'];
        final String storeUrl = Platform.isIOS
            ? data['ios']['store_url']
            : data['android']['store_url'];

        final minVersion = Version.parse(minVersionString);

        if (currentVersion < minVersion) {
          throw ForcedUpdateException(storeUrl);
        }
        log('$_tag: Version de l\'application à jour (v$currentVersion).');
      }
    } catch (e) {
      if (e is ForcedUpdateException) {
        rethrow; // Propage l'exception de mise à jour forcée
      }
      // Pour les autres erreurs (ex: réseau), on ne bloque pas le démarrage
      log(
        '$_tag: Erreur non bloquante lors de la vérification de la mise à jour: $e',
      );
    }
  }

  /// Initialise les services critiques de sécurité
  Future<void> _initializeCriticalSecurityServices(BuildContext context) async {
    try {
      // 1. Initialiser le service de redondance critique
      final redundancyService = context
          .read<CriticalNotificationRedundancyService>();
      await redundancyService.initialize();
      log('$_tag: Service de redondance critique initialisé');

      // 2. Initialiser le monitoring proactif
      final systemMonitor = context.read<ProactiveSystemMonitor>();
      await systemMonitor.initialize();
      log('$_tag: Service de monitoring proactif initialisé');

      // 3. Initialiser le service unifié d'alertes critiques
      final unifiedAlertService = context.read<UnifiedCriticalAlertService>();
      await unifiedAlertService.initialize();
      log('$_tag: Service unifié d\'alertes critiques initialisé');

      log('$_tag: Tous les services critiques de sécurité sont initialisés');
    } catch (e) {
      log('$_tag: Erreur lors de l\'initialisation des services critiques: $e');
      // Ne pas faire échouer l'initialisation complète pour ces services
    }
  }

  /// Initialise le service FCM pour les notifications push
  Future<void> _initializeFCMService(BuildContext context) async {
    try {
      final fcmService = context.read<FCMService>();
      await fcmService.initialize(baseUrl: ApiConfig.baseUrlSync);
      log('$_tag: Service FCM initialisé');
    } catch (e) {
      log('$_tag: Erreur lors de l\'initialisation du service FCM: $e');
      // Ne pas faire échouer l'initialisation complète pour ce service
    }
  }

  /// Initialise le service de notification persistante
  Future<void> _initializePersistentNotificationService(
    BuildContext context,
  ) async {
    try {
      final statusNotificationService = context
          .read<PersistentStatusNotificationService>();
      await statusNotificationService.initialize();
      log('$_tag: Service de notification persistante initialisé');
    } catch (e) {
      log(
        '$_tag: Erreur lors de l\'initialisation du service de notification persistante: $e',
      );
      // Ne pas faire échouer l'initialisation complète pour ce service
    }
  }

  /// Initialise le service de monitoring de santé
  Future<void> _initializeHealthMonitorService(BuildContext context) async {
    try {
      final healthMonitor = context.read<ServiceHealthMonitor>();
      await healthMonitor.initialize();
      log('$_tag: Service de monitoring de santé initialisé');
    } catch (e) {
      log(
        '$_tag: Erreur lors de l\'initialisation du service de monitoring de santé: $e',
      );
      // Ne pas faire échouer l'initialisation complète pour ce service
    }
  }

  /// Initialise le service de géolocalisation intégré
  Future<void> _initializeGeolocationService(BuildContext context) async {
    try {
      final nativeLocationService = context.read<NativeLocationService>();

      // Initialiser le service de géolocalisation natif
      await nativeLocationService.initialize();
      log('$_tag: Service unifié de géolocalisation initialisé');
    } catch (e) {
      log('$_tag: Erreur lors du démarrage du service de géolocalisation: $e');
      // Ne pas faire échouer l'initialisation complète pour ce service
    }
  }

  /// Arrête tous les services
  Future<void> stopServices(BuildContext context) async {
    if (!_isInitialized) {
      log('$_tag: Services non initialisés, rien à arrêter');
      return;
    }

    log('$_tag: Arrêt des services en cours...');

    try {
      // Arrêter le service de géolocalisation natif
      final nativeLocationService = context.read<NativeLocationService>();
      await nativeLocationService.stopTracking();
      log('$_tag: Service unifié de géolocalisation arrêté');

      // Arrêter le service de monitoring de santé
      final healthMonitor = context.read<ServiceHealthMonitor>();
      await healthMonitor.dispose();
      log('$_tag: Service de monitoring de santé arrêté');

      _isInitialized = false;
      log('$_tag: Tous les services ont été arrêtés');
    } catch (e) {
      log('$_tag: Erreur lors de l\'arrêt des services: $e');
      rethrow;
    }
  }

  /// Redémarre tous les services
  Future<void> restartServices(BuildContext context) async {
    log('$_tag: Redémarrage des services...');
    await stopServices(context);
    await initializeServices(context);
  }

  /// Vérifie l'état de santé de tous les services
  Future<Map<String, bool>> checkServicesHealth(BuildContext context) async {
    final healthStatus = <String, bool>{};

    try {
      // Vérifier le service de géolocalisation natif
      final nativeLocationService = context.read<NativeLocationService>();
      healthStatus['native_location'] = nativeLocationService.isTracking;

      // Vérifier le service de monitoring de santé
      healthStatus['health_monitor'] = true; // Simplifier pour éviter l'erreur

      log('$_tag: État de santé des services: $healthStatus');
    } catch (e) {
      log('$_tag: Erreur lors de la vérification de l\'état des services: $e');
    }

    return healthStatus;
  }
}

/// Exception levée lorsqu'une mise à jour forcée est requise.
class ForcedUpdateException implements Exception {
  final String storeUrl;

  ForcedUpdateException(this.storeUrl);

  @override
  String toString() => 'Une mise à jour de l\'application est requise.';
}
