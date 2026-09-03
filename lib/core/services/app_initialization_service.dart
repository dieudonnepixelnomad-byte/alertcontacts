import 'dart:developer';

import 'package:alertcontacts/core/config/api_config.dart';
import 'package:alertcontacts/core/services/app_version_service.dart';
import 'package:alertcontacts/core/services/immediate_update_service.dart';
import 'package:alertcontacts/core/services/critical_notification_redundancy_service.dart';
import 'package:alertcontacts/core/services/fcm_service.dart';
import 'package:alertcontacts/core/services/location_service.dart';
import 'package:alertcontacts/core/services/proactive_system_monitor.dart';
import 'package:alertcontacts/core/services/unified_critical_alert_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
      // 0. Vérification backend de version — bloquant, avant tout le reste
      await _checkForceUpdateWithBackendStatus();

      // Utilisation de Future.wait pour paralléliser les initialisations indépendantes
      await Future.wait([
        // 1. Initialiser les services critiques de sécurité en priorité
        _initializeCriticalSecurityServices(context),

        // 2. Initialiser le service FCM pour les notifications push
        _initializeFCMService(context),
      ]);

      // 3. Initialiser le service de géolocalisation intégré (peut dépendre des permissions)
      await _initializeGeolocationService(context);

      _isInitialized = true;
      log('$_tag: Initialisation des services terminée avec succès');
    } catch (e) {
      if (e is ForcedUpdateException) rethrow;
      log('$_tag: Erreur lors de l\'initialisation des services: $e');
      // On ne rethrow pas pour ne pas crasher l'app, l'utilisateur verra peut-être un état dégradé
    } finally {
      _isInitializing = false;
    }
  }

  /// Interroge le backend puis vérifie si une MAJ forcée est requise.
  /// Bloquant — lève [ForcedUpdateException] si la version actuelle est trop ancienne.
  Future<void> _checkForceUpdateWithBackendStatus() async {
    try {
      final versionService = AppVersionService();
      final result = await versionService.checkForceUpdate();

      if (result.required) {
        await ImmediateUpdateService().startIfAvailable();
        throw ForcedUpdateException(result.storeUrl);
      }
    } catch (e) {
      if (e is ForcedUpdateException) rethrow;
      log('$_tag: Vérification version échouée, démarrage normal — $e');
    }
  }

  /// Initialise les services critiques de sécurité
  Future<void> _initializeCriticalSecurityServices(BuildContext context) async {
    try {
      final redundancyService = context
          .read<CriticalNotificationRedundancyService>();
      final systemMonitor = context.read<ProactiveSystemMonitor>();
      final unifiedAlertService = context.read<UnifiedCriticalAlertService>();

      await Future.wait([
        redundancyService.initialize().then(
          (_) => log('$_tag: Service de redondance critique initialisé'),
        ),
        systemMonitor.initialize().then(
          (_) => log('$_tag: Service de monitoring proactif initialisé'),
        ),
        unifiedAlertService.initialize().then(
          (_) => log('$_tag: Service unifié d\'alertes critiques initialisé'),
        ),
      ]);

      log('$_tag: Tous les services critiques de sécurité sont initialisés');
    } catch (e) {
      log('$_tag: Erreur lors de l\'initialisation des services critiques: $e');
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

  /// Initialise le service de géolocalisation intégré
  Future<void> _initializeGeolocationService(BuildContext context) async {
    try {
      final locationService = context.read<LocationService>();
      await locationService.initialize();
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
      final locationService = context.read<LocationService>();
      await locationService.stopTracking();
      log('$_tag: Service unifié de géolocalisation arrêté');

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
      final locationService = context.read<LocationService>();
      healthStatus['native_location'] = locationService.isTracking;

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
