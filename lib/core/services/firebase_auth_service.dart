import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../errors/auth_exceptions.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream des changements d'état d'authentification Firebase
  /* Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges(); */

  /// Utilisateur Firebase actuellement connecté
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Connexion avec Google
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const SyncErrorException();
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is GoogleSignInCancelledException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Connexion avec Apple
  Future<firebase_auth.User> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw const AppleSignInCancelledException();
    }
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider(
        'apple.com',
      ).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const SyncErrorException();
      }

      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppleSignInCancelledException();
      }
      throw AppleSignInFailedException(e.message);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      if (e is AppleSignInCancelledException) rethrow;
      throw AppleSignInFailedException(e.toString());
    }
  }

  /// Envoyer un magic link de connexion (email sign-in link)
  /// Firebase Dynamic Links est fermé depuis août 2025 — on utilise App Links / Universal Links
  Future<void> sendSignInLink({
    required String email,
    required String continueUrl,
  }) async {
    try {
      final settings = firebase_auth.ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: true,
      );
      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Vérifier si le lien entrant est un email sign-in link
  bool isSignInWithEmailLink(String link) =>
      _firebaseAuth.isSignInWithEmailLink(link);

  /// Compléter la connexion via email link
  Future<firebase_auth.User> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      final user = credential.user;
      if (user == null) throw const SyncErrorException();
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Obtenir le token ID Firebase pour l'échange avec l'API
  Future<String> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotFoundException();
      }

      final token = await user.getIdToken(forceRefresh);
      if (token == null) {
        throw const SyncErrorException();
      }
      return token;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Mapper les exceptions Firebase vers nos exceptions personnalisées
  AuthException _mapFirebaseException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundException();
      case 'user-disabled':
        return const UserDisabledException();
      case 'too-many-requests':
        return const TooManyRequestsException();
      case 'network-request-failed':
        return const NetworkException();
      default:
        return UnknownAuthException('${e.code}: ${e.message}');
    }
  }
}
