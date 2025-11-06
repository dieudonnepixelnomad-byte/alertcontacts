import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
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

  /// Inscription avec email et mot de passe
  Future<firebase_auth.User> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const SyncErrorException();
      }

      // Mettre à jour le nom d'affichage
      await user.updateDisplayName(name);

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Connexion avec email et mot de passe
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      log(
        'Connexion avec email et mot de passe (via Firebase)',
        name: 'FirebaseAuthService.signInWithEmailAndPassword',
      );
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier si l'email est vérifié
      if (!credential.user!.emailVerified) {
        log(
          'Email non vérifié, lançant EmailNotVerifiedException',
          name: 'FirebaseAuthService.signInWithEmailAndPassword',
        );
        throw const EmailNotVerifiedException();
      }

      final user = credential.user;
      if (user == null) {
        throw const SyncErrorException();
      }

      log(
        'Connexion réussie avec email: $email',
        name: 'FirebaseAuthService.signInWithEmailAndPassword',
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

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

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotFoundException();
      }
      await user.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  /// Vérifier si l'email est vérifié (recharge les données utilisateur)
  Future<bool> checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UserNotFoundException();
      }

      await user.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
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
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsException();
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'weak-password':
        return const WeakPasswordException();
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
