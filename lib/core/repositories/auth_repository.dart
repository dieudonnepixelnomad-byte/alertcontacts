import 'dart:async';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_auth_service.dart';
import '../services/prefs_service.dart';
import '../services/batch_sender_service.dart';
import '../services/gps_trace_recorder.dart';
import '../services/zones_cache_service.dart';
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

  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    await _firebaseAuth.signInWithGoogle();
    // L'état sera mis à jour via authStateChanges
  }

  /// Connexion avec Apple
  Future<void> signInWithApple() async {
    await _firebaseAuth.signInWithApple();
    // L'état sera mis à jour via authStateChanges
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

      // Un compte Laravel vient d'être créé alors que l'app avait déjà un
      // profil : les données locales décrivent donc un backend supprimé.
      // Réinitialiser avant de sauvegarder la nouvelle session propre.
      if (_apiAuth.lastFirebaseLoginCreatedAccount && savedUser != null) {
        await _prefs.resetForRecreatedBackendAccount();
        ZonesCacheService().invalidateAllCache();
        GpsTraceRecorder().stop();
        await BatchSenderService().clearOfflineCache();
      }

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
    // Persiste l'UID Firebase pour les isolates headless et Swift
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      await _prefs.setFirebaseUid(uid);
    }
  }

  /// Récupérer le token Bearer sauvegardé
  Future<String?> _getSavedBearerToken() async {
    return await _prefs.getBearerToken();
  }

  /// Nettoyer l'état d'authentification local
  Future<void> _clearAuthState() async {
    await Future.wait([
      _prefs.clearBearerToken(),
      _prefs.clearUserProfile(),
      _prefs.clearFirebaseUid(),
    ]);
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
