import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/services/permissions_service.dart';
import 'package:alertcontacts/features/about/presentation/about_page.dart';
import 'package:alertcontacts/features/app_shell/presentation/app_shell.dart';
import 'package:alertcontacts/features/auth/presentation/login_page.dart';
import 'package:alertcontacts/features/auth/presentation/magic_link_sent_page.dart';
import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/features/auth/providers/auth_state.dart';
import 'package:alertcontacts/features/permissions/presentation/permission_location_page.dart';
import 'package:alertcontacts/features/permissions/presentation/permission_notification_page.dart';
import 'package:alertcontacts/features/permissions/presentation/permission_background_location_page.dart';
import 'package:provider/provider.dart';
import 'package:alertcontacts/features/splash/presentation/forced_update_page.dart';
import 'package:alertcontacts/features/proches/presentation/accept_invitation_page.dart';
import 'package:alertcontacts/features/proches/presentation/add_proche_page.dart';
import 'package:alertcontacts/features/splash/presentation/splash_page.dart';
import 'package:alertcontacts/features/zones_securite/presentation/safezone_setup_wizard.dart';
import 'package:alertcontacts/features/safezone_setup/presentation/setup_introduction_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// === Pages ===
import '../features/user_setup/presentation/user_setup_wizard.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/aha_sandbox_page.dart';
import '../features/onboarding/presentation/aha_celebration_page.dart';
import '../features/onboarding/presentation/personalization_page.dart';
import '../features/onboarding/presentation/onboarding_slides_page.dart';
import '../features/onboarding/presentation/onboarding_invitation_page.dart';
import '../features/onboarding/presentation/onboarding_notification_permission_page.dart';
import '../features/onboarding/presentation/onboarding_location_permission_page.dart';
import '../features/onboarding/presentation/onboarding_zone_creation_page.dart';
import '../features/onboarding/presentation/onboarding_confirmation_page.dart';
import '../features/onboarding/presentation/onboarding_resume_page.dart';
import '../features/zones_securite/presentation/pages/zone_creation_success_page.dart';
import '../features/zones_danger/presentation/danger_zone_introduction_page.dart';
import '../features/zones_danger/presentation/danger_zone_setup_wizard.dart';
import '../features/zones_danger/presentation/danger_zone_creation_success_page.dart';
import '../features/alertes/presentation/alert_detail_page.dart';
// Imports supprimés car navigation interne :
// import '../features/proches/screens/proches_screen.dart';
// import '../features/proches/screens/create_invitation_screen.dart';
// import '../features/proches/screens/invitation_detail_screen.dart';
import '../features/alertes/presentation/alertes_page.dart';
import '../features/zones_danger/presentation/ignored_zones_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/notification_settings_page.dart';
// import '../features/invitations/presentation/accept_invitation_page.dart';
import '../debug_permissions.dart';
import '../debug_fcm.dart';
import '../features/debug/presentation/notification_test_page.dart';
import '../debug_fcm_test.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/feedback/presentation/feedback_page.dart';
import '../features/help/presentation/help_page.dart';

/// Routes nommées centralisées
abstract class AppRoutes {
  static const splash = '/';
  static const forcedUpdate = '/forced-update';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const magicLinkSent = '/auth/magic-link-sent';
  static const userSetup = '/user-setup';
  static const permissionLocation = '/permission/location';
  static const permissionNotification = '/permission/notification';
  static const permissionBackgroundLocation = '/permission/background-location';
  static const permissions = '/permissions';
  static const appShell = '/app-shell';
  static const safezoneSetup = '/safezone/setup';
  static const dangerCreate = '/zone-danger/create';
  static const dangerDetail = '/zone-danger/detail';
  static const safezoneCreate = '/zone-securite/create';
  static const proches = '/proches';
  static const addProche = '/proches/add';
  // Routes supprimées car gérées en interne par ProchesScreen :
  // - prochesManagement
  // - createInvitation
  // - invitationDetail
  static const alertes = '/alertes';
  static const ignoredZones = '/ignored-zones';
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const profile = '/profile';
  static const about = '/about';
  static const help = '/help';
  static const feedback = '/feedback';
  static const acceptInvite = '/invitations/accept';
  static const debugPermissions = '/debug/permissions';
  static const debugFcm = '/debug/fcm';
  static const debugNotifications = '/debug/notifications';

  // Onboarding V4
  static const onboardingSlides = '/onboarding/slides';

  // Onboarding V2 (kept for backward compat)
  static const onboardingSandbox = '/onboarding/sandbox';
  static const onboardingCelebration = '/onboarding/celebration';
  static const onboardingPersonalization = '/onboarding/personalization';
  static const onboardingBackgroundDisclosure = '/onboarding/background-disclosure';
  static const onboardingInvitation = '/onboarding/invitation';
  static const onboardingNotificationPermission = '/onboarding/notification-permission';
  static const onboardingLocationPermission = '/onboarding/location-permission';
  static const onboardingZoneCreation = '/onboarding/zone-creation';
  static const onboardingConfirmation = '/onboarding/confirmation';
  static const onboardingResume = '/onboarding/resume';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: AppRoutes.splash,
      // Gestion d'erreur personnalisée
      errorPageBuilder: (context, state) {
        // Pour les erreurs, afficher une page d'erreur standard
        return MaterialPage(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Page non trouvée')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Page non trouvée'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.splash),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: SplashPage()),
        ),
        GoRoute(
          path: AppRoutes.forcedUpdate,
          name: 'forcedUpdate',
          builder: (context, state) {
            final storeUrl = state.extra as String?;
            return ForcedUpdatePage(storeUrl: storeUrl ?? '');
          },
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (ctx, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.userSetup,
          name: 'user_setup',
          builder: (ctx, state) => const UserSetupWizard(),
        ),
        GoRoute(
          path: AppRoutes.auth,
          name: 'auth',
          builder: (ctx, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.magicLinkSent,
          name: 'magic_link_sent',
          builder: (ctx, state) {
            final email = Uri.decodeComponent(
              state.uri.queryParameters['email'] ?? '',
            );
            return MagicLinkSentPage(email: email);
          },
        ),

        GoRoute(
          path: AppRoutes.permissionLocation,
          name: 'permission_location',
          builder: (ctx, state) => const PermissionLocationPage(),
        ),
        GoRoute(
          path: AppRoutes.permissionNotification,
          name: 'permission_notification',
          builder: (ctx, state) => const PermissionNotificationPage(),
        ),
        GoRoute(
          path: AppRoutes.permissionBackgroundLocation,
          name: 'permission_background_location',
          builder: (ctx, state) => const PermissionBackgroundLocationPage(),
        ),
        GoRoute(
          path: AppRoutes.appShell,
          name: 'home',
          builder: (ctx, state) => const AppShell(),
        ),
        GoRoute(
          path: AppRoutes.safezoneSetup,
          name: 'safezone_setup',
          builder: (ctx, state) => const SetupIntroductionPage(),
          routes: [
            GoRoute(
              path: 'zone-config',
              name: 'safezone_setup_config',
              builder: (ctx, state) => const SafeZoneSetupWizard(),
            ),
            GoRoute(
              path: 'success',
              builder: (context, state) {
                final zoneName =
                    state.uri.queryParameters['zoneName'] ?? 'Zone';
                final iconKey = state.uri.queryParameters['iconKey'] ?? 'home';
                return ZoneCreationSuccessPage(
                  zoneName: zoneName,
                  iconKey: iconKey,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.dangerCreate,
          name: 'danger_create',
          builder: (ctx, state) => const DangerZoneIntroductionPage(),
          routes: [
            GoRoute(
              path: 'wizard',
              name: 'danger_zone_wizard',
              builder: (ctx, state) => const DangerZoneSetupWizard(),
            ),
            GoRoute(
              path: 'success',
              name: 'danger_zone_success',
              builder: (context, state) =>
                  const DangerZoneCreationSuccessPage(),
            ),
          ],
        ),
        GoRoute(
          path: '${AppRoutes.dangerDetail}/:zoneId',
          name: 'danger_detail',
          builder: (ctx, state) =>
              AlertDetailPage(zoneId: state.pathParameters['zoneId']!),
        ),
        GoRoute(
          path: AppRoutes.addProche,
          name: 'add_proche',
          builder: (ctx, state) => const InviteProchePage(),
        ),
        // Routes supprimées car gérées en interne par ProchesScreen :
        // - prochesManagement -> ProchesScreen est maintenant dans AppShell
        // - createInvitation -> Navigation directe dans ProchesScreen
        // - invitationDetail -> Navigation directe dans ProchesScreen
        GoRoute(
          path: '/invitations/accept',
          name: 'accept_invitation',
          builder: (ctx, state) => AcceptInvitationPage(
            token: state.uri.queryParameters['t'] ?? '',
            prefilledPin: state.uri.queryParameters['pin'],
          ),
        ),
        GoRoute(
          path: AppRoutes.alertes,
          name: 'alertes',
          builder: (ctx, state) => const AlertesPage(),
        ),
        GoRoute(
          path: AppRoutes.ignoredZones,
          name: 'ignored_zones',
          builder: (ctx, state) => const IgnoredZonesPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (ctx, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          name: 'notificationSettings',
          builder: (ctx, state) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (ctx, state) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.about,
          name: 'about',
          builder: (ctx, state) => const AboutPage(),
        ),
        GoRoute(
          path: AppRoutes.help,
          name: 'help',
          builder: (ctx, state) => const HelpPage(),
        ),
        GoRoute(
          path: AppRoutes.feedback,
          name: 'feedback',
          builder: (ctx, state) => const FeedbackPage(),
        ),
        GoRoute(
          path: AppRoutes.debugPermissions,
          name: 'debugPermissions',
          builder: (ctx, state) => const DebugPermissionsPage(),
        ),
        GoRoute(
          path: AppRoutes.debugFcm,
          name: 'debugFcm',
          builder: (ctx, state) => const DebugFCMPage(),
        ),
        GoRoute(
          path: AppRoutes.debugNotifications,
          name: 'debugNotifications',
          builder: (ctx, state) => const NotificationTestPage(),
        ),
        GoRoute(
          path: '/debug/fcm-test',
          name: 'debugFcmTest',
          builder: (ctx, state) => const FCMTestWidget(),
        ),

        // ── Onboarding V4 ─────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.onboardingSlides,
          name: 'onboarding_slides',
          builder: (ctx, state) => const OnboardingSlidesPage(),
        ),

        // ── Onboarding V2 (routes kept, V4 redirect bypasses most) ────────
        GoRoute(
          path: AppRoutes.onboardingSandbox,
          name: 'onboarding_sandbox',
          builder: (ctx, state) => const AhaSandboxPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingCelebration,
          name: 'onboarding_celebration',
          builder: (ctx, state) => const AhaCelebrationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingPersonalization,
          name: 'onboarding_personalization',
          builder: (ctx, state) => const PersonalizationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingBackgroundDisclosure,
          name: 'onboarding_background_disclosure',
          builder: (ctx, state) => const PermissionBackgroundLocationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingInvitation,
          name: 'onboarding_invitation',
          builder: (ctx, state) => const OnboardingInvitationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingNotificationPermission,
          name: 'onboarding_notification_permission',
          builder: (ctx, state) => const OnboardingNotificationPermissionPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingLocationPermission,
          name: 'onboarding_location_permission',
          builder: (ctx, state) => const OnboardingLocationPermissionPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingZoneCreation,
          name: 'onboarding_zone_creation',
          builder: (ctx, state) => const OnboardingZoneCreationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingConfirmation,
          name: 'onboarding_confirmation',
          builder: (ctx, state) => const OnboardingConfirmationPage(),
        ),
        GoRoute(
          path: AppRoutes.onboardingResume,
          name: 'onboarding_resume',
          builder: (ctx, state) => const OnboardingResumePage(),
        ),
      ],
      redirect: (ctx, state) async {
        final prefs = PrefsService();
        final authNotifier = ctx.read<AuthNotifier>();
        final isAuthenticated =
            authNotifier.state.status == AuthStatus.authenticated;
        final location = state.uri.path;

        // ── Toujours autoriser ────────────────────────────────────────────
        if (location == AppRoutes.splash) return null;
        if (location == AppRoutes.forcedUpdate) return null;
        if (location.startsWith(AppRoutes.acceptInvite)) return null;
        if (location.startsWith('/debug/')) return null;

        final onboardingDone = await prefs.isOnboardingDone();

        // ── Authentifié + onboarding terminé → accès libre ───────────────
        if (isAuthenticated && onboardingDone) {
          if (location == AppRoutes.auth) return AppRoutes.appShell;
          return null;
        }

        // ── Pages pré-auth toujours autorisées ────────────────────────────
        const preAuthPages = [
          AppRoutes.onboardingSlides,
          AppRoutes.onboardingPersonalization,
          AppRoutes.onboardingBackgroundDisclosure,
          AppRoutes.auth,
        ];
        if (preAuthPages.contains(location)) return null;
        if (location.startsWith('/auth/')) return null;

        // ── Pas authentifié → cascade pré-auth ───────────────────────────
        if (!isAuthenticated) {
          // Si l'utilisateur s'était déjà connecté, ne pas forcer /auth
          // (silentSignIn peut être encore en cours, ou offline temporaire)
          final hadLoggedIn = await prefs.hasLoggedIn();
          if (hadLoggedIn) return null;

          final results = await Future.wait([
            prefs.isOnboardingSlidesSeen(),
            prefs.isUserSetupDone(),
            PermissionsService.isBackgroundLocationDisclosed(),
          ]);
          final slidesSeen = results[0];
          final personaDone = results[1];
          final disclosureDone = results[2];

          if (!slidesSeen) return AppRoutes.onboardingSlides;
          if (!personaDone) return AppRoutes.onboardingPersonalization;
          if (!disclosureDone) return AppRoutes.onboardingBackgroundDisclosure;
          return AppRoutes.auth;
        }

        // ── Authentifié, onboarding incomplet → cascade post-auth ─────────
        if (location == AppRoutes.onboardingInvitation) return null;

        final inviteDone = await prefs.isOnboardingInviteDone();
        if (!inviteDone) return AppRoutes.onboardingInvitation;

        // Toutes les étapes faites → marquer terminé
        await prefs.setOnboardingDone();
        return AppRoutes.appShell;
      },
    );
  }
}
