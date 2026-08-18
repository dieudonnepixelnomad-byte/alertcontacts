import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/services/http_client.dart';
import 'core/services/api_v1_client.dart';
import 'core/services/api_incidents_service.dart';
import 'core/services/api_routes_service.dart';
import 'features/alertes/providers/incident_provider.dart';
import 'features/trajets/providers/route_provider.dart';
import 'package:alertcontacts/generated/l10n/app_localizations.dart';
import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/core/repositories/auth_repository.dart';
import 'package:alertcontacts/core/repositories/safezone_repository.dart';
import 'package:alertcontacts/core/repositories/dangerzone_repository.dart';
import 'package:alertcontacts/core/repositories/zones_repository.dart';
import 'package:alertcontacts/core/repositories/ignored_danger_zone_repository.dart';
import 'package:alertcontacts/core/repositories/profile_repository.dart';
import 'package:alertcontacts/core/repositories/feedback_repository.dart';
import 'package:alertcontacts/features/profile/providers/profile_provider.dart';
import 'package:alertcontacts/features/feedback/providers/feedback_provider.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/services/firebase_auth_service.dart';
import 'package:alertcontacts/core/services/api_auth_service.dart';
import 'package:alertcontacts/core/services/api_safezone_service.dart';
import 'package:alertcontacts/core/services/api_dangerzone_service.dart';
import 'package:alertcontacts/core/services/api_zones_service.dart';
import 'package:alertcontacts/core/services/api_invitation_service.dart';
import 'package:alertcontacts/core/services/api_relationship_service.dart';
import 'package:alertcontacts/core/services/api_activities_service.dart';
import 'package:alertcontacts/core/services/api_ignored_danger_zones_service.dart';
import 'package:alertcontacts/core/services/api_alerts_service.dart';
import 'package:alertcontacts/core/services/api_location_service.dart';
import 'package:alertcontacts/features/activities/repositories/activities_repository.dart';
import 'package:alertcontacts/features/settings/providers/activities_provider.dart';
import 'package:alertcontacts/core/config/api_config.dart';
import 'package:alertcontacts/core/services/batch_sender_service.dart';
import 'package:alertcontacts/features/zones/providers/zones_notifier.dart';
import 'package:alertcontacts/features/zones_danger/providers/danger_zone_notifier.dart';
import 'package:alertcontacts/features/zones_danger/providers/ignored_danger_zones_provider.dart';
import 'package:alertcontacts/features/proches/providers/invitation_provider.dart';
import 'package:alertcontacts/features/proches/providers/relationship_provider.dart';
import 'package:alertcontacts/features/alertes/providers/alert_provider.dart';
import 'package:alertcontacts/core/providers/auth_manager.dart';
import 'package:alertcontacts/core/services/deep_link_service.dart';
import 'package:alertcontacts/core/services/app_initialization_service.dart';
import 'package:alertcontacts/features/alertes/services/permissions_manager_service.dart';
import 'package:alertcontacts/core/services/location_service.dart';
import 'package:alertcontacts/core/services/fcm_service.dart';
import 'package:alertcontacts/core/services/critical_notification_redundancy_service.dart';
import 'package:alertcontacts/core/services/proactive_system_monitor.dart';
import 'package:alertcontacts/core/services/unified_critical_alert_service.dart';
import 'package:alertcontacts/core/services/contact_rtdb_service.dart';
import 'package:alertcontacts/core/services/device_info_service.dart';
import 'package:alertcontacts/core/services/subscription_service.dart';
import 'package:alertcontacts/core/providers/map_type_notifier.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AlertContactApp extends StatefulWidget {
  const AlertContactApp({super.key});

  @override
  State<AlertContactApp> createState() => _AlertContactAppState();
}

class _AlertContactAppState extends State<AlertContactApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create();

  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI système : status/navigation bars lisibles
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MultiProvider(
      providers: [
        // Services de base
        Provider<AppHttpClient>(create: (_) => AppHttpClient()),
        Provider<PrefsService>(create: (_) => PrefsService()),
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        Provider<ApiAuthService>(
          create: (context) => ApiAuthService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<ApiSafeZoneService>(
          create: (context) => ApiSafeZoneService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<ApiDangerZoneService>(
          create: (context) => ApiDangerZoneService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<ApiZonesService>(
          create: (context) => ApiZonesService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<ApiInvitationService>(create: (_) => ApiInvitationService()),
        Provider<ApiRelationshipService>(
          create: (_) => ApiRelationshipService(),
        ),
        Provider<ApiActivitiesService>(create: (_) => ApiActivitiesService()),
        Provider<ApiIgnoredDangerZonesService>(
          create: (_) => ApiIgnoredDangerZonesService(),
        ),
        Provider<ApiAlertsService>(
          create: (context) => ApiAlertsService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        // Socle API v1 — incidents communautaires & trajets (CDC V4.1 §8)
        Provider<ApiV1Client>(
          create: (context) => ApiV1Client(client: context.read<AppHttpClient>()),
        ),
        Provider<ApiIncidentsService>(
          create: (context) => ApiIncidentsService(client: context.read<ApiV1Client>()),
        ),
        Provider<ApiRoutesService>(
          create: (context) => ApiRoutesService(client: context.read<ApiV1Client>()),
        ),
        Provider<ApiLocationService>(
          create: (context) => ApiLocationService(
            baseUrl: ApiConfig.baseUrlSync,
            client: context.read<AppHttpClient>(),
          ),
        ),
        // Services
        Provider<FCMService>(create: (_) => FCMService()),
        Provider<PermissionsManagerService>(
          create: (_) => PermissionsManagerService(),
        ),
        Provider<LocationService>(
                create: (_) => LocationService(),
        ),
        Provider<AppInitializationService>(
          create: (_) => AppInitializationService(),
        ),
        Provider<BatchSenderService>(
          create: (_) => BatchSenderService(),
        ),
        // Services critiques de sécurité
        Provider<CriticalNotificationRedundancyService>(
          create: (_) => CriticalNotificationRedundancyService(),
        ),
        Provider<ProactiveSystemMonitor>(
          create: (_) => ProactiveSystemMonitor(),
        ),
        Provider<UnifiedCriticalAlertService>(
          create: (_) => UnifiedCriticalAlertService(),
        ),
        Provider<DeviceInfoService>(create: (_) => DeviceInfoService()),
        // Repository
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            firebaseAuth: context.read<FirebaseAuthService>(),
            apiAuth: context.read<ApiAuthService>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        Provider<SafeZoneRepository>(
          create: (context) => SafeZoneRepository(
            apiService: context.read<ApiSafeZoneService>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        Provider<DangerZoneRepository>(
          create: (context) => DangerZoneRepository(
            apiService: context.read<ApiDangerZoneService>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        Provider<ZonesRepository>(
          create: (context) => ZonesRepository(
            apiService: context.read<ApiZonesService>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        Provider<ActivitiesRepository>(
          create: (context) =>
              ActivitiesRepository(context.read<ApiActivitiesService>()),
        ),
        Provider<IgnoredDangerZoneRepository>(
          create: (context) => IgnoredDangerZoneRepository(
            apiService: context.read<ApiIgnoredDangerZonesService>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        Provider<ProfileRepository>(
          create: (context) => ProfileRepository(
            prefs: context.read<PrefsService>(),
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<FeedbackRepository>(
          create: (context) => FeedbackRepository(
            client: context.read<AppHttpClient>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        // Notifier
        ChangeNotifierProvider<AuthNotifier>(
          create: (context) {
            final authNotifier = AuthNotifier(context.read<AuthRepository>());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authNotifier.setRouter(_router);
              DeepLinkService.initialize(_router, authNotifier: authNotifier);
            });
            return authNotifier;
          },
        ),
        ChangeNotifierProxyProvider<AuthNotifier, SubscriptionService>(
          create: (_) => SubscriptionService.instance,
          update: (context, authNotifier, subscriptionService) {
            final firebaseUid = authNotifier.isAuthenticated
                ? context.read<FirebaseAuthService>().currentUser?.uid
                : null;
            subscriptionService?.syncAppUserId(firebaseUid);
            return subscriptionService ?? SubscriptionService.instance;
          },
        ),
        ChangeNotifierProvider<ZonesNotifier>(
          create: (context) => ZonesNotifier(context.read<ZonesRepository>()),
        ),
        ChangeNotifierProvider<DangerZoneNotifier>(
          create: (context) => DangerZoneNotifier(
            apiService: context.read<ApiDangerZoneService>(),
            repository: context.read<DangerZoneRepository>(),
            prefs: context.read<PrefsService>(),
          ),
        ),
        ChangeNotifierProvider<InvitationProvider>(
          create: (_) => InvitationProvider(),
        ),
        ChangeNotifierProvider<RelationshipProvider>(
          create: (_) => RelationshipProvider(),
        ),
        ChangeNotifierProxyProvider<RelationshipProvider, ContactRtdbService>(
          create: (_) => ContactRtdbService(),
          update: (_, relProvider, rtdbService) {
            (rtdbService ?? ContactRtdbService())
                .updateContacts(relProvider.acceptedRelationships);
            return rtdbService ?? ContactRtdbService();
          },
        ),
        ChangeNotifierProvider<AlertProvider>(
          create: (context) => AlertProvider(
            context.read<ApiAlertsService>(),
            context.read<PrefsService>(),
          ),
        ),
        // Incidents communautaires V4.1 — remplace progressivement la partie
        // « alertes communautaires » d'AlertProvider (§4)
        ChangeNotifierProvider<IncidentProvider>(
          create: (context) => IncidentProvider(
            context.read<ApiIncidentsService>(),
            context.read<PrefsService>(),
          ),
        ),
        ChangeNotifierProvider<RouteProvider>(
          create: (context) => RouteProvider(
            context.read<ApiRoutesService>(),
            context.read<PrefsService>(),
          ),
        ),
        ChangeNotifierProvider<ActivitiesProvider>(
          create: (context) => ActivitiesProvider(
            context.read<ActivitiesRepository>(),
          ),
        ),
        ChangeNotifierProvider<IgnoredDangerZonesProvider>(
          create: (context) => IgnoredDangerZonesProvider(
            repository: context.read<IgnoredDangerZoneRepository>(),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (context) => ProfileProvider(
            context.read<ProfileRepository>(),
          ),
        ),
        ChangeNotifierProvider<FeedbackProvider>(
          create: (context) => FeedbackProvider(
            feedbackRepository: context.read<FeedbackRepository>(),
            deviceInfoService: context.read<DeviceInfoService>(),
          ),
        ),
        ChangeNotifierProvider<MapTypeNotifier>(
          create: (context) => MapTypeNotifier(context.read<PrefsService>()),
        ),

        // Gestionnaire d'authentification
        ChangeNotifierProxyProvider5<
          AuthNotifier,
          InvitationProvider,
          RelationshipProvider,
          IgnoredDangerZonesProvider,
          ProfileProvider,
          AuthManager
        >(
          create: (context) => AuthManager(context.read<AuthNotifier>()),
          update:
              (
                context,
                authNotifier,
                invitationProvider,
                relationshipProvider,
                ignoredDangerZonesProvider,
                profileProvider,
                authManager,
              ) {
                authManager ??= AuthManager(authNotifier);
                authManager.registerAuthAwareProvider(invitationProvider);
                authManager.registerAuthAwareProvider(relationshipProvider);
                authManager.registerAuthAwareProvider(ignoredDangerZonesProvider);
                authManager.registerAuthAwareProvider(profileProvider);
                authManager.registerAuthAwareProvider(context.read<BatchSenderService>());
                return authManager;
              },
        ),
      ],
      child: MaterialApp.router(
        title: 'AlertContacts',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
        // Configuration des localisations
        locale: const Locale('fr'), // Langue par défaut
        supportedLocales: const [
          Locale('fr', ''), // Français
          Locale('en', ''), // Anglais
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
