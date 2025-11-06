import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/services/permissions_service.dart';
import 'package:alertcontacts/core/services/pending_deep_link_service.dart';
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
import '../features/user_setup/presentation/user_setup_wizard.dart';

// === Pages (crée-les si besoin) ===
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

        final location = state.uri.path;
        final fullLocation = state.uri.toString();

        // DEBUG: Log de la navigation
        print('🔄 ROUTER DEBUG: Navigating to: $fullLocation');
        print('🔄 ROUTER DEBUG: Path: $location');
        print('🔄 ROUTER DEBUG: Scheme: ${state.uri.scheme}');
        print('🔄 ROUTER DEBUG: Host: ${state.uri.host}');

        // Ignorer complètement les URLs alertcontact:// - elles sont gérées par DeepLinkService
        if (state.uri.scheme == 'alertcontact') {
          print(
            '🔄 ROUTER DEBUG: Detected alertcontact:// scheme, redirecting to splash',
          );
          return AppRoutes.splash;
        }

        final goingToSplash = location == AppRoutes.splash;
        final goingToOnboarding = location == AppRoutes.onboarding;
        final goingToAuth =
            location == AppRoutes.auth || location == AppRoutes.register;
        final goingToPermissions =
            location == AppRoutes.permissionLocation ||
            location == AppRoutes.permissionNotification ||
            location == AppRoutes.permissionBackgroundLocation;

        // Routes protégées qui nécessitent une authentification complète
        final protectedRoutes = [
          AppRoutes.appShell,
          AppRoutes.safezoneSetup,
          AppRoutes.dangerCreate,
          AppRoutes.dangerDetail,
          AppRoutes.safezoneCreate,
          AppRoutes.proches,
          AppRoutes.addProche,
          // Routes supprimées car gérées en interne par ProchesScreen :
          // - AppRoutes.prochesManagement,
          // - AppRoutes.createInvitation,
          // - AppRoutes.invitationDetail,
          AppRoutes.alertes,
          AppRoutes.ignoredZones,
          AppRoutes.settings,
          AppRoutes.profile,
          AppRoutes.feedback,
          // Note: AppRoutes.acceptInvite retiré car il doit être accessible même sans auth complète
        ];
        final goingToProtectedRoute = protectedRoutes.contains(location);
        final goingToAcceptInvite = location.startsWith('/invitations/accept');

        // Routes publiques qui ne nécessitent pas de permissions
        final publicRoutes = [
          AppRoutes.about,
          AppRoutes.debugPermissions,
          AppRoutes.debugFcm,
        ];
        final goingToPublicRoute = publicRoutes.contains(location);

        print('🔄 ROUTER DEBUG: goingToAcceptInvite: $goingToAcceptInvite');
        print('🔄 ROUTER DEBUG: goingToPublicRoute: $goingToPublicRoute');

        // 1. Gestion de l'onboarding
        if (!onboardingDone &&
            !goingToSplash &&
            !goingToOnboarding &&
            !goingToPublicRoute) {
          print('🔄 ROUTER DEBUG: Redirecting to onboarding');
          return AppRoutes.onboarding;
        }

        // 2. Gestion des permissions après onboarding (AVANT authentification)
        if (onboardingDone &&
            !goingToPermissions &&
            !goingToAuth &&
            !goingToSplash &&
            !goingToOnboarding &&
            !goingToPublicRoute) {
          final permissionsSetupComplete =
              await PermissionsService.isPermissionsSetupComplete();

          // Si les permissions ne sont pas configurées
          if (!permissionsSetupComplete) {
            // Vérifier quelle permission demander en premier
            final locationGranted =
                await PermissionsService.isLocationPermissionGranted();
            if (!locationGranted) {
              print('🔄 ROUTER DEBUG: Redirecting to location permission');
              return AppRoutes.permissionLocation;
            }

            final notificationGranted =
                await PermissionsService.isNotificationPermissionGranted();
            if (!notificationGranted) {
              print('🔄 ROUTER DEBUG: Redirecting to notification permission');
              return AppRoutes.permissionNotification;
            }

            // Vérifier la permission de géolocalisation en arrière-plan
            final backgroundLocationGranted =
                await PermissionsService.isBackgroundLocationPermissionGranted();
            if (!backgroundLocationGranted) {
              print(
                '🔄 ROUTER DEBUG: Redirecting to background location permission',
              );
              return AppRoutes.permissionBackgroundLocation;
            }

            // Si toutes les permissions sont accordées, marquer comme terminé
            await PermissionsService.markPermissionsSetupComplete();
          }
        }

        // 3. Vérification de l'authentification (APRÈS permissions)
        final authNotifier = ctx.read<AuthNotifier>();
        final authState = authNotifier.state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;

        print('🔄 ROUTER DEBUG: isAuthenticated: $isAuthenticated');
        print('🔄 ROUTER DEBUG: authState.status: ${authState.status}');

        // Si permissions OK mais pas authentifié et va vers une route protégée
        final permissionsSetupComplete =
            await PermissionsService.isPermissionsSetupComplete();

        if (onboardingDone &&
            permissionsSetupComplete &&
            !isAuthenticated &&
            goingToProtectedRoute) {
          print(
            '🔄 ROUTER DEBUG: Permissions OK but not authenticated, redirecting to auth (protected route)',
          );
          return AppRoutes.auth;
        }

        // Cas spécial: acceptation d'invitation - nécessite au minimum une authentification
        if (goingToAcceptInvite && !isAuthenticated) {
          print(
            '🔄 ROUTER DEBUG: Going to accept invite but not authenticated, redirecting to auth',
          );
          // Rediriger vers l'authentification mais permettre le retour vers l'invitation
          return AppRoutes.auth;
        }

        // Si on va vers l'acceptation d'invitation et qu'on est authentifié
        if (goingToAcceptInvite && isAuthenticated) {
          print(
            '🔄 ROUTER DEBUG: Going to accept invite and authenticated, allowing access',
          );
          return null; // Permettre l'accès direct
        }

        // 4. Gestion du setup initial (première zone de sécurité) après permissions
        if (isAuthenticated && !goingToAcceptInvite) {
          final permissionsSetupComplete =
              await PermissionsService.isPermissionsSetupComplete();
          final initialSetupDone = await prefsService.isInitialSetupDone();

          // Si permissions OK mais setup initial pas fait, et qu'on va vers une route protégée
          if (permissionsSetupComplete &&
              !initialSetupDone &&
              goingToProtectedRoute) {
            // Exception: permettre d'aller vers safezone_setup
            if (location != AppRoutes.safezoneSetup &&
                !location.startsWith('/safezone/setup')) {
              return AppRoutes.safezoneSetup;
            }
          }
        }

        // 5. Si authentifié et va vers auth/register, rediriger selon l'état
        if (isAuthenticated && goingToAuth) {
          // Vérifier s'il y a un deep link en attente (invitation)
          final hasPendingDeepLink =
              await PendingDeepLinkService.hasPendingDeepLink();

          // Si il y a un deep link en attente, laisser passer pour permettre le rejeu
          if (hasPendingDeepLink) {
            return null; // Laisser l'utilisateur aller vers /auth pour le rejeu
          }

          final initialSetupDone = await prefsService.isInitialSetupDone();

          if (initialSetupDone) {
            // Tout est configuré, aller vers l'app shell
            return AppRoutes.appShell;
          } else {
            // Setup initial pas fait
            return AppRoutes.safezoneSetup;
          }
        }

        return null;
      },
      debugLogDiagnostics: true,
    );
  }
}
