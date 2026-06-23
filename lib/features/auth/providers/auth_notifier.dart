import 'dart:async';
import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/models/user.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/config/api_config.dart';
import 'auth_state.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;
  GoRouter? _router;
  AuthState _state = const AuthState();

  AuthNotifier(this._authRepository);

  /// Définir le router pour la gestion des deep links
  void setRouter(GoRouter router) {
    _router = router;
  }

  // Getters pour accéder à l'état
  AuthState get state => _state;
  AuthStatus get status => _state.status;
  User? get user => _state.user;
  String? get message => _state.message;
  String? get errorCode => _state.errorCode;

  // Getters utilitaires
  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get isAuthenticating => _state.status == AuthStatus.authenticating;
  // Méthode privée pour mettre à jour l'état
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _setUserAnalyticsProperties() async {
    AnalyticsService().setUserTier('free');
    final persona = await PrefsService().getOnboardingPersona();
    if (persona != null) AnalyticsService().setProfileType(persona);
  }

  /// Initialiser FCM après une connexion réussie
  Future<void> _initializeFCMAfterLogin(String bearerToken) async {
    try {
      final fcmService = FCMService();

      // Mettre à jour les credentials FCM avec le token fraîchement obtenu
      fcmService.updateCredentials(
        baseUrl: ApiConfig.baseUrlSync,
        bearerToken: bearerToken,
      );

      await fcmService.initializeAfterLogin();
    } catch (e) {
      // Crashlytics Log Trace
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  // Méthode pour effacer les messages
  void clearMessage() {
    _updateState(_state.copyWith(message: null, errorCode: null));
  }

  /// Authentification silencieuse au démarrage de l'application
  Future<void> silentSignIn() async {
    if (_state.status == AuthStatus.authenticating) return;

    _updateState(_state.copyWith(status: AuthStatus.authenticating));

    try {
      // Essayer de rafraîchir la session existante
      final user = await _authRepository.refreshSession();

      if (user != null) {
        log(
          'AuthNotifier.silentSignIn: Utilisateur authentifié: ${user.email}',
        );
        _updateState(
          _state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            message: null,
            errorCode: null,
          ),
        );
        await AnalyticsService().setUser(user.id, email: user.email);
        await _setUserAnalyticsProperties();

        final prefsService = PrefsService();
        await prefsService.setHasLoggedIn(true);
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          await _initializeFCMAfterLogin(bearerToken);
        } else {}

        // Rejouer les deep links en attente après authentification silencieuse
        if (_router != null) {
          log(
            'AuthNotifier.silentSignIn: Tentative de rejouer les deep links en attente',
          );
          await DeepLinkService.replayPendingDeepLink(_router!);
        }
      } else {
        log('AuthNotifier.silentSignIn: Aucune session valide trouvée');
        _updateState(
          _state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            message: null,
            errorCode: null,
          ),
        );
      }
    } catch (error) {
      log('AuthNotifier.silentSignIn: Erreur: $error');
      // En cas d'erreur, on considère l'utilisateur comme non authentifié
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          message: null,
          errorCode: null,
        ),
      );
    }
  }

  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    _updateState(
      _state.copyWith(
        status: AuthStatus.authenticating,
        message: null,
        errorCode: null,
      ),
    );

    try {
      log('AuthNotifier.signInWithGoogle: Tentative de connexion Google');

      await _authRepository.signInWithGoogle();

      // Après la connexion Google, récupérer les données utilisateur via l'API
      final user = await _authRepository.refreshSession();

      if (user != null) {
        log(
          'AuthNotifier.signInWithGoogle: Connexion Google réussie pour ${user.email}',
        );
        _updateState(
          _state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            message: 'Connexion Google réussie',
          ),
        );
        AnalyticsService().logLoginSuccess('google');
        await AnalyticsService().setUser(user.id, email: user.email);
        await _setUserAnalyticsProperties();

        final prefsService = PrefsService();
        await prefsService.setHasLoggedIn(true);
        // Initialiser FCM après connexion réussie
        log(
          '🔐 AuthNotifier.signInWithGoogle: Récupération du bearerToken pour FCM...',
        );
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          log(
            '🔐 AuthNotifier.signInWithGoogle: bearerToken récupéré, initialisation FCM...',
          );
          await _initializeFCMAfterLogin(bearerToken);
        } else {
          log(
            '❌ AuthNotifier.signInWithGoogle: bearerToken null, FCM non initialisé',
          );
        }
      } else {
        _updateState(
          _state.copyWith(
            status: AuthStatus.unauthenticated,
            message: 'Connexion Google annulée',
            errorCode: 'google_sign_in_cancelled',
          ),
        );
      }
    } on UserDisabledException {
      log('AuthNotifier.signInWithGoogle: Compte désactivé');
      AnalyticsService().logLoginFailure(method: 'google', errorCode: 'user_disabled');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Votre compte a été désactivé',
          errorCode: 'user_disabled',
        ),
      );
    } catch (error) {
      log('AuthNotifier.signInWithGoogle: Erreur inattendue: $error');
      AnalyticsService().logLoginFailure(method: 'google', errorCode: 'google_sign_in_error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Erreur lors de la connexion Google',
          errorCode: 'google_sign_in_error',
        ),
      );
    }
  }

  /// Connexion avec Apple
  Future<void> signInWithApple() async {
    _updateState(
      _state.copyWith(
        status: AuthStatus.authenticating,
        message: null,
        errorCode: null,
      ),
    );

    try {
      log('AuthNotifier.signInWithApple: Tentative de connexion Apple');

      await _authRepository.signInWithApple();

      final user = await _authRepository.refreshSession();

      if (user != null) {
        log(
          'AuthNotifier.signInWithApple: Connexion Apple réussie pour ${user.email}',
        );
        _updateState(
          _state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            message: 'Connexion Apple réussie',
          ),
        );
        AnalyticsService().logLoginSuccess('apple');
        await AnalyticsService().setUser(user.id, email: user.email);
        await _setUserAnalyticsProperties();

        final prefsService = PrefsService();
        await prefsService.setHasLoggedIn(true);
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          await _initializeFCMAfterLogin(bearerToken);
        }
      } else {
        _updateState(
          _state.copyWith(
            status: AuthStatus.unauthenticated,
            message: 'Connexion Apple annulée',
            errorCode: 'apple_sign_in_cancelled',
          ),
        );
      }
    } on AppleSignInCancelledException {
      log('AuthNotifier.signInWithApple: Annulé par l\'utilisateur');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: null,
          errorCode: null,
        ),
      );
    } on UserDisabledException {
      log('AuthNotifier.signInWithApple: Compte désactivé');
      AnalyticsService().logLoginFailure(method: 'apple', errorCode: 'user_disabled');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Votre compte a été désactivé',
          errorCode: 'user_disabled',
        ),
      );
    } on AppleSignInFailedException catch (error) {
      log('AuthNotifier.signInWithApple: Échec Apple: $error');
      AnalyticsService().logLoginFailure(method: 'apple', errorCode: 'apple_sign_in_error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Erreur lors de la connexion Apple',
          errorCode: 'apple_sign_in_error',
        ),
      );
    } catch (error) {
      log('AuthNotifier.signInWithApple: Erreur inattendue: $error');
      AnalyticsService().logLoginFailure(method: 'apple', errorCode: 'apple_sign_in_error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Erreur lors de la connexion Apple',
          errorCode: 'apple_sign_in_error',
        ),
      );
    }
  }

  /// Envoyer un Magic Link (email sign-in link)
  Future<void> sendMagicLink(String email) async {
    _updateState(_state.copyWith(
      status: AuthStatus.authenticating,
      message: null,
      errorCode: null,
    ));

    try {
      const continueUrl = 'https://alertcontacts.web.app/magic-link';

      final firebaseAuthService = FirebaseAuthService();
      await firebaseAuthService.sendSignInLink(
        email: email,
        continueUrl: continueUrl,
      );

      // Store email for link verification (Firebase requirement)
      final prefs = PrefsService();
      await prefs.setPendingMagicLinkEmail(email);

      AnalyticsService().logSignUp('magic_link');

      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'magic_link_sent',
        errorCode: null,
      ));
    } on TooManyRequestsException {
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Trop de tentatives. Veuillez réessayer plus tard',
        errorCode: 'too_many_requests',
      ));
    } catch (e) {
      log('AuthNotifier.sendMagicLink error: $e');
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Erreur lors de l\'envoi du lien. Vérifiez votre email.',
        errorCode: 'magic_link_error',
      ));
    }
  }

  /// Compléter la connexion via un email link reçu en deep link
  Future<void> verifyMagicLink(String emailLink) async {
    final firebaseAuthService = FirebaseAuthService();
    if (!firebaseAuthService.isSignInWithEmailLink(emailLink)) return;

    final prefs = PrefsService();
    final email = await prefs.getPendingMagicLinkEmail();
    if (email == null) return;

    _updateState(_state.copyWith(
      status: AuthStatus.authenticating,
      message: null,
      errorCode: null,
    ));

    try {
      await firebaseAuthService.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      await prefs.clearPendingMagicLinkEmail();

      final user = await _authRepository.refreshSession();
      if (user != null) {
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          message: null,
        ));
        AnalyticsService().logLoginSuccess('magic_link');
        await AnalyticsService().setUser(user.id, email: user.email);
        await _setUserAnalyticsProperties();
        final bearerToken = await prefs.getBearerToken();
        if (bearerToken != null) await _initializeFCMAfterLogin(bearerToken);
      } else {
        _updateState(_state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Lien invalide ou expiré',
          errorCode: 'magic_link_invalid',
        ));
      }
    } catch (e) {
      log('AuthNotifier.verifyMagicLink error: $e');
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Lien invalide ou expiré',
        errorCode: 'magic_link_invalid',
      ));
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      log('AuthNotifier.signOut: Déconnexion en cours');

      await _authRepository.signOut();
      await PrefsService().setHasLoggedIn(false);

      log('AuthNotifier.signOut: Déconnexion réussie');
      AnalyticsService().logLogout();
      await AnalyticsService().clearUser();
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          message: 'Déconnexion réussie',
          errorCode: null,
        ),
      );
    } catch (error) {
      log('AuthNotifier.signOut: Erreur lors de la déconnexion: $error');
      // Même en cas d'erreur, on considère l'utilisateur comme déconnecté
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          message: 'Déconnexion effectuée',
          errorCode: null,
        ),
      );
    }
  }

}
