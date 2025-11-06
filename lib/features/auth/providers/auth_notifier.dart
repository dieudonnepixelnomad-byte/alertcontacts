import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/models/user.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/fcm_service.dart';
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
  bool get needsEmailVerification =>
      _state.status == AuthStatus.needsEmailVerification;

  // Méthode privée pour mettre à jour l'état
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Initialiser FCM après une connexion réussie
  Future<void> _initializeFCMAfterLogin(String bearerToken) async {
    log('🔐 AuthNotifier._initializeFCMAfterLogin: DÉBUT');
    debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - DÉBUT');
    log('🔐 AuthNotifier._initializeFCMAfterLogin: bearerToken = ${bearerToken.substring(0, 10)}...');
    debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - bearerToken = ${bearerToken.substring(0, 10)}...');
    log('🔐 AuthNotifier._initializeFCMAfterLogin: baseUrl = ${ApiConfig.baseUrlSync}');
    debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - baseUrl = ${ApiConfig.baseUrlSync}');
    
    try {
      final fcmService = FCMService();
      log('🔐 AuthNotifier._initializeFCMAfterLogin: FCMService instance créée');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - FCMService instance créée');

      // Mettre à jour les credentials FCM avec le token fraîchement obtenu
      log('🔐 AuthNotifier._initializeFCMAfterLogin: Mise à jour des credentials FCM...');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - Mise à jour des credentials FCM...');
      fcmService.updateCredentials(
        baseUrl: ApiConfig.baseUrlSync,
        bearerToken: bearerToken,
      );
      log('🔐 AuthNotifier._initializeFCMAfterLogin: Credentials FCM mises à jour');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - Credentials FCM mises à jour');

      // Initialiser FCM après connexion
      log('🔐 AuthNotifier._initializeFCMAfterLogin: Initialisation FCM...');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - Initialisation FCM...');
      await fcmService.initializeAfterLogin();
      log('🔐 AuthNotifier._initializeFCMAfterLogin: FCM initialisé avec succès');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - FCM initialisé avec succès');

      log('🔐 AuthNotifier._initializeFCMAfterLogin: FIN - SUCCÈS');
      debugPrint('🔐 FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - FIN - SUCCÈS');
    } catch (e) {
      log('❌ AuthNotifier._initializeFCMAfterLogin: ERREUR: $e');
      debugPrint('❌ FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - ERREUR: $e');
      log('❌ AuthNotifier._initializeFCMAfterLogin: Stack trace: ${StackTrace.current}');
      debugPrint('❌ FLUTTER DEBUG: AuthNotifier._initializeFCMAfterLogin - Stack trace: ${StackTrace.current}');
      // Ne pas faire échouer la connexion si FCM échoue
    }
  }

  // Méthode pour effacer les messages
  void clearMessage() {
    _updateState(_state.copyWith(message: null, errorCode: null));
  }

  /// Authentification silencieuse au démarrage de l'application
  Future<void> silentSignIn() async {
    debugPrint('🚀 FLUTTER DEBUG: ===== SILENT SIGN IN DÉMARRÉ =====');
    
    if (_state.status == AuthStatus.authenticating) return;

    _updateState(_state.copyWith(status: AuthStatus.authenticating));

    try {
      log(
        'AuthNotifier.silentSignIn: Tentative d\'authentification silencieuse',
      );
      debugPrint('🚀 FLUTTER DEBUG: Tentative d\'authentification silencieuse');

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

        // Initialiser FCM après connexion silencieuse réussie
        log('🔐 AuthNotifier.silentSignIn: Récupération du bearerToken pour FCM...');
        debugPrint('🔐 FLUTTER DEBUG: AuthNotifier.silentSignIn - Récupération du bearerToken pour FCM...');
        final prefsService = PrefsService();
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          log('🔐 AuthNotifier.silentSignIn: bearerToken récupéré, initialisation FCM...');
          debugPrint('🔐 FLUTTER DEBUG: AuthNotifier.silentSignIn - bearerToken récupéré, initialisation FCM...');
          await _initializeFCMAfterLogin(bearerToken);
        } else {
          log('❌ AuthNotifier.silentSignIn: bearerToken null, FCM non initialisé');
          debugPrint('❌ FLUTTER DEBUG: AuthNotifier.silentSignIn - bearerToken null, FCM non initialisé');
        }

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

  /// Connexion avec email et mot de passe
  Future<void> signInWithEmail(String email, String password) async {
    _updateState(
      _state.copyWith(
        status: AuthStatus.authenticating,
        message: null,
        errorCode: null,
      ),
    );

    try {
      log('AuthNotifier.signInWithEmail: Tentative de connexion pour $email');

      await _authRepository.signInWithEmail(email: email, password: password);

      // Après la connexion Firebase, récupérer les données utilisateur via l'API
      final user = await _authRepository.refreshSession();

      if (user != null) {
        log(
          'AuthNotifier.signInWithEmail: Connexion réussie pour ${user.email}',
        );
        _updateState(
          _state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            message: 'Connexion réussie',
          ),
        );

        // Initialiser FCM après connexion réussie
        log('🔐 AuthNotifier.signInWithEmail: Récupération du bearerToken pour FCM...');
        final prefsService = PrefsService();
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          log('🔐 AuthNotifier.signInWithEmail: bearerToken récupéré, initialisation FCM...');
          await _initializeFCMAfterLogin(bearerToken);
        } else {
          log('❌ AuthNotifier.signInWithEmail: bearerToken null, FCM non initialisé');
        }
      } else {
        _updateState(
          _state.copyWith(
            status: AuthStatus.unauthenticated,
            message: 'Échec de la connexion',
            errorCode: 'sign_in_failed',
          ),
        );
      }
    } on EmailNotVerifiedException {
      log('AuthNotifier.signInWithEmail: Email non vérifié');
      _updateState(
        _state.copyWith(
          status: AuthStatus.needsEmailVerification,
          message: 'Veuillez vérifier votre email avant de vous connecter',
          errorCode: 'email_not_verified',
        ),
      );
    } on InvalidCredentialsException {
      log('AuthNotifier.signInWithEmail: Identifiants invalides');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Email ou mot de passe incorrect',
          errorCode: 'invalid_credentials',
        ),
      );
    } on UserDisabledException {
      log('AuthNotifier.signInWithEmail: Compte désactivé');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Votre compte a été désactivé',
          errorCode: 'user_disabled',
        ),
      );
    } on TooManyRequestsException {
      log('AuthNotifier.signInWithEmail: Trop de tentatives');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Trop de tentatives. Veuillez réessayer plus tard',
          errorCode: 'too_many_requests',
        ),
      );
    } catch (error) {
      log('AuthNotifier.signInWithEmail: Erreur inattendue: $error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Une erreur inattendue s\'est produite',
          errorCode: 'unexpected_error',
        ),
      );
    }
  }

  /// Inscription avec email et mot de passe
  Future<void> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    _updateState(
      _state.copyWith(
        status: AuthStatus.authenticating,
        message: null,
        errorCode: null,
      ),
    );

    try {
      log(
        'AuthNotifier.registerWithEmail: Tentative d\'inscription pour $email',
      );

      await _authRepository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      // Note: Cette ligne ne devrait jamais être atteinte car EmailNotVerifiedException
      // est toujours lancée après inscription (email non vérifié)
      log('AuthNotifier.registerWithEmail: Inscription réussie pour $email');
    } on EmailNotVerifiedException {
      log(
        'AuthNotifier.registerWithEmail: Email non vérifié - redirection vers vérification',
      );
      _updateState(
        _state.copyWith(
          status: AuthStatus.needsEmailVerification,
          message: 'Inscription réussie. Veuillez vérifier votre email',
          errorCode: 'email_not_verified',
        ),
      );
    } on EmailAlreadyInUseException {
      log('AuthNotifier.registerWithEmail: Email déjà utilisé');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Cette adresse email est déjà utilisée',
          errorCode: 'email_already_in_use',
        ),
      );
    } on WeakPasswordException {
      log('AuthNotifier.registerWithEmail: Mot de passe trop faible');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Le mot de passe est trop faible',
          errorCode: 'weak_password',
        ),
      );
    } catch (error) {
      log('AuthNotifier.registerWithEmail: Erreur inattendue: $error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Une erreur inattendue s\'est produite',
          errorCode: 'unexpected_error',
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

        // Initialiser FCM après connexion réussie
        log('🔐 AuthNotifier.signInWithGoogle: Récupération du bearerToken pour FCM...');
        final prefsService = PrefsService();
        final bearerToken = await prefsService.getBearerToken();
        if (bearerToken != null) {
          log('🔐 AuthNotifier.signInWithGoogle: bearerToken récupéré, initialisation FCM...');
          await _initializeFCMAfterLogin(bearerToken);
        } else {
          log('❌ AuthNotifier.signInWithGoogle: bearerToken null, FCM non initialisé');
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
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Votre compte a été désactivé',
          errorCode: 'user_disabled',
        ),
      );
    } catch (error) {
      log('AuthNotifier.signInWithGoogle: Erreur inattendue: $error');
      _updateState(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Erreur lors de la connexion Google',
          errorCode: 'google_sign_in_error',
        ),
      );
    }
  }

  /// Connexion avec Apple (non implémentée)
  Future<void> signInWithApple() async {
    _updateState(
      _state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Connexion Apple non encore implémentée',
        errorCode: 'apple_sign_in_not_implemented',
      ),
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      log('AuthNotifier.signOut: Déconnexion en cours');

      await _authRepository.signOut();

      log('AuthNotifier.signOut: Déconnexion réussie');
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

  /// Envoi d'un email de réinitialisation de mot de passe
  Future<void> sendPasswordReset(String email) async {
    _updateState(_state.copyWith(message: null, errorCode: null));

    try {
      log(
        'AuthNotifier.sendPasswordReset: Envoi email de réinitialisation pour $email',
      );

      await _authRepository.sendPasswordReset(email);

      log('AuthNotifier.sendPasswordReset: Email envoyé avec succès');
      _updateState(
        _state.copyWith(message: 'Email de réinitialisation envoyé'),
      );
    } on UserNotFoundException {
      log('AuthNotifier.sendPasswordReset: Utilisateur non trouvé');
      _updateState(
        _state.copyWith(
          message: 'Aucun compte associé à cette adresse email',
          errorCode: 'user_not_found',
        ),
      );
    } catch (error) {
      log('AuthNotifier.sendPasswordReset: Erreur inattendue: $error');
      _updateState(
        _state.copyWith(
          message: 'Erreur lors de l\'envoi de l\'email',
          errorCode: 'password_reset_error',
        ),
      );
    }
  }

  /// Vérification de l'email
  Future<void> checkEmailVerification() async {
    try {
      log('AuthNotifier.checkEmailVerification: Vérification du statut email');

      final isVerified = await _authRepository.checkEmailVerification();

      if (isVerified) {
        log(
          'AuthNotifier.checkEmailVerification: Email vérifié, utilisateur authentifié',
        );

        // Récupérer les données utilisateur via l'API
        final user = await _authRepository.refreshSession();

        _updateState(
          _state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            message: 'Email vérifié avec succès',
          ),
        );
      } else {
        log('AuthNotifier.checkEmailVerification: Email non encore vérifié');
        _updateState(
          _state.copyWith(
            message: 'Email non encore vérifié',
            errorCode: 'email_not_verified',
          ),
        );
      }
    } catch (error) {
      log('AuthNotifier.checkEmailVerification: Erreur: $error');
      _updateState(
        _state.copyWith(
          message: 'Erreur lors de la vérification',
          errorCode: 'verification_error',
        ),
      );
    }
  }

  /// Renvoi de l'email de vérification
  Future<void> resendEmailVerification() async {
    try {
      log('AuthNotifier.resendEmailVerification: Renvoi email de vérification');

      await _authRepository.sendEmailVerification();

      log('AuthNotifier.resendEmailVerification: Email renvoyé avec succès');
      _updateState(_state.copyWith(message: 'Email de vérification renvoyé'));
    } catch (error) {
      log('AuthNotifier.resendEmailVerification: Erreur: $error');
      _updateState(
        _state.copyWith(
          message: 'Erreur lors du renvoi de l\'email',
          errorCode: 'resend_verification_error',
        ),
      );
    }
  }
}
