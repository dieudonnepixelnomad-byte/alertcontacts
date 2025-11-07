import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/services/permissions_service.dart';
import 'package:alertcontacts/features/about/presentation/about_page.dart';
import 'package:alertcontacts/features/app_shell/presentation/app_shell.dart';
import 'package:alertcontacts/features/auth/presentation/login_page.dart';
import 'package:alertcontacts/features/auth/presentation/register_page.dart';
import 'package:alertcontacts/features/auth/pages/email_verification_page.dart';
import 'package:alertcontacts/features/auth/pages/forgot_password_page.dart';
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

// === Pages (crée-les si besoin) ===
import '../features/user_setup/presentation/user_setup_wizard.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/zones_securite/presentation/pages/zone_creation_success_page.dart';
import '../features/zones_danger/presentation/danger_zone_introduction_page.dart';
import '../features/zones_danger/presentation/danger_zone_setup_wizard.dart';
import '../features/zones_danger/presentation/danger_zone_creation_success_page.dart';
import '../features/zones_danger/presentation/danger_detail_page.dart';
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
  static const register = '/register';
  static const emailVerification = '/email-verification';
  static const forgotPassword = '/forgot-password';
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
          path: AppRoutes.register,
          name: 'register',
          builder: (ctx, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.emailVerification,
          name: 'email_verification',
          builder: (ctx, state) => const EmailVerificationPage(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgot_password',
          builder: (ctx, state) => const ForgotPasswordPage(),
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
              DangerDetailPage(zoneId: state.pathParameters['zoneId']!),
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
      ],
      // Redirection:
      // 1. Vérifier l'onboarding
      // 2. Vérifier l'authentification
      // 3. Vérifier les permissions (après auth, avant app shell)
      // 4. Permettre la navigation normale
      redirect: (ctx, state) async {
        final prefsService = PrefsService();
        final onboardingDone = await prefsService.isOnboardingDone();
        final authNotifier = ctx.read<AuthNotifier>();
        final isAuthenticated = authNotifier.state.status == AuthStatus.authenticated;

        final location = state.uri.path;

        // Autoriser l'accès inconditionnel à certaines pages
        final allowedPaths = [
          AppRoutes.splash,
          AppRoutes.forcedUpdate,
          AppRoutes.onboarding,
          AppRoutes.auth,
          AppRoutes.register,
          AppRoutes.forgotPassword,
          AppRoutes.emailVerification,
        ];
        if (allowedPaths.contains(location) || location.startsWith(AppRoutes.acceptInvite)) {
          return null;
        }

        // 1. Onboarding
        if (!onboardingDone) {
          return AppRoutes.onboarding;
        }

        // 2. Authentification
        if (!isAuthenticated) {
          return AppRoutes.auth;
        }

        // À partir d'ici, l'utilisateur est authentifié.

        // Si l'utilisateur authentifié tente d'accéder aux pages d'auth, le rediriger.
        if (location == AppRoutes.auth || location == AppRoutes.register) {
          return AppRoutes.appShell;
        }

        // 3. Permissions
        final permissionsSetupComplete = await PermissionsService.isPermissionsSetupComplete();
        final isGoingToPermissionPage = location.startsWith('/permission');

        print('Router Redirect: permissionsSetupComplete: $permissionsSetupComplete');
        print('Router Redirect: isGoingToPermissionPage: $isGoingToPermissionPage');
        print('Router Redirect: location: $location');

        if (!permissionsSetupComplete && !isGoingToPermissionPage) {
          final locationGranted = await PermissionsService.isLocationPermissionGranted();
          print('Router Redirect: locationGranted: $locationGranted');
          if (!locationGranted) return AppRoutes.permissionLocation;

          final notificationGranted = await PermissionsService.isNotificationPermissionGranted();
          print('Router Redirect: notificationGranted: $notificationGranted');
          if (!notificationGranted) return AppRoutes.permissionNotification;

          final backgroundLocationGranted = await PermissionsService.isBackgroundLocationPermissionGranted();
          print('Router Redirect: backgroundLocationGranted: $backgroundLocationGranted');
          if (!backgroundLocationGranted) return AppRoutes.permissionBackgroundLocation;

          // Si toutes les permissions sont accordées, marquer le setup comme complet
          await PermissionsService.markPermissionsSetupComplete();
        }
        
        // Si les permissions ne sont pas complètes, mais que l'utilisateur navigue déjà vers une page de permission, autoriser.
        if (!permissionsSetupComplete && isGoingToPermissionPage) {
            return null;
        }

        // 4. User Setup
        final userSetupDone = await prefsService.isUserSetupDone();
        if (!userSetupDone && location != AppRoutes.userSetup) {
          return AppRoutes.userSetup;
        }

        // 5. Initial SafeZone Setup
        final initialSetupDone = await prefsService.isInitialSetupDone();
        if (!initialSetupDone && !location.startsWith(AppRoutes.safezoneSetup)) {
          return AppRoutes.safezoneSetup;
        }

        return null; // Pas de redirection
      },
    );
  }
}
