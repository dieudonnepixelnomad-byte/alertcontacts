import 'dart:async';
import 'dart:developer';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_auth_service.dart';
import '../services/prefs_service.dart';
import '../errors/auth_exceptions.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuth;
  final ApiAuthService _apiAuth;
  final PrefsService _prefs;

  AuthRepository({
    required FirebaseAuthService firebaseAuth,
    required ApiAuthService apiAuth,
    required PrefsService prefs,
  }) : _firebaseAuth = firebaseAuth,
       _apiAuth = apiAuth,
       _prefs = prefs;

  /// Inscription avec email et mot de passe (via Firebase)
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final firebaseUser = await _firebaseAuth.registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );

    // Après l'inscription, l'utilisateur doit vérifier son email
    // On déclenche explicitement l'exception pour passer à l'état needsEmailVerification
    if (!firebaseUser.emailVerified) {
      throw const EmailNotVerifiedException();
    }
  }

  /// Inscription directe via l'API Laravel (sans Firebase)
  Future<User> registerWithApi({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      log(
        'Inscription directe via l\'API Laravel',
        name: 'AuthRepository.registerWithApi',
      );
      final user = await _apiAuth.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      log(
        'Utilisateur créé via l\'API Laravel',
        name: 'AuthRepository.registerWithApi',
      );

      // Sauvegarder le token pour la persistance
      await _saveAuthState(user, _apiAuth.bearerToken);

      log(
        'Token sauvegardé localement',
        name: 'AuthRepository.registerWithApi',
      );

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Connexion avec email et mot de passe (via Firebase)
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    log(
      'Connexion avec email et mot de passe (via Firebase)',
      name: 'AuthRepository.signInWithEmail',
    );
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // L'état sera mis à jour via authStateChanges qui gérera la vérification d'email
    log(
      'Connexion réussie avec email: $email',
      name: 'AuthRepository.signInWithEmail',
    );
  }

  /// Connexion directe via l'API Laravel (sans Firebase)
  Future<User> signInWithApi({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _apiAuth.login(email: email, password: password);

      // Sauvegarder le token pour la persistance
      await _saveAuthState(user, _apiAuth.bearerToken);

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    await _firebaseAuth.signInWithGoogle();
    // L'état sera mis à jour via authStateChanges
  }

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email);
  }

  /// Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.sendEmailVerification();
  }

  /// Vérifier si l'email est vérifié
  Future<bool> checkEmailVerification() async {
    return await _firebaseAuth.checkEmailVerification();
  }

  /// Rafraîchir la session (en cas d'erreur 401)
  Future<User?> refreshSession() async {
    try {
      // Restaurer le token Bearer sauvegardé au démarrage
      final savedToken = await _getSavedBearerToken();
      final savedUser = await _prefs.getUserProfile();
      
      if (savedToken != null) {
        _apiAuth.setBearerToken(savedToken);
      }

      // Si nous avons un token et un profil utilisateur sauvegardés, essayer de les utiliser
      if (savedToken != null && savedUser != null) {
        // Essayer d'abord de rafraîchir le token JWT directement
        try {
          final user = await _apiAuth.refreshToken();
          await _saveAuthState(user, _apiAuth.bearerToken);
          return user;
        } catch (e) {
          // Si le refresh JWT échoue, continuer avec Firebase comme fallback
        }
      }

      // Si pas de token/profil sauvegardé ou si le refresh a échoué, utiliser Firebase comme fallback
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null; // Pas d'utilisateur Firebase connecté
      }

      // Rafraîchir le token Firebase et échanger
      final idToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      final userData = _extractUserDataFromFirebase(firebaseUser);
      final user = await _apiAuth.refreshSession(idToken, userData);

      // Sauvegarder le nouveau token
      await _saveAuthState(user, _apiAuth.bearerToken);

      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _apiAuth.logout()]);
    } finally {
      // Nettoyer les données locales même en cas d'erreur
      await _clearAuthState();
    }
  }

  /// Sauvegarder l'état d'authentification localement
  Future<void> _saveAuthState(User user, String? bearerToken) async {
    if (bearerToken != null) {
      await _prefs.setBearerToken(bearerToken);
    }
    await _prefs.setUserProfile(user);
  }

  /// Récupérer le token Bearer sauvegardé
  Future<String?> _getSavedBearerToken() async {
    return await _prefs.getBearerToken();
  }

  /// Nettoyer l'état d'authentification local
  Future<void> _clearAuthState() async {
    await Future.wait([_prefs.clearBearerToken(), _prefs.clearUserProfile()]);
  }

  /// Extraire les données utilisateur Firebase pour l'API
  Map<String, dynamic> _extractUserDataFromFirebase(dynamic firebaseUser) {
    return {
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'name': firebaseUser.displayName,
      'picture': firebaseUser.photoURL,
      'phone_number': firebaseUser.phoneNumber,
      'email_verified': firebaseUser.emailVerified,
      'provider': firebaseUser.providerData.isNotEmpty
          ? firebaseUser.providerData.first.providerId
          : 'firebase',
    };
  }

  /// Nettoyer les ressources
  void dispose() {
    _apiAuth.dispose();
  }
}
