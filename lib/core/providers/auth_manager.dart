import 'package:flutter/foundation.dart';
import '../../features/auth/providers/auth_notifier.dart';
import 'auth_aware_provider.dart';

/// Gestionnaire qui synchronise l'authentification avec tous les providers
class AuthManager extends ChangeNotifier {
  final AuthNotifier _authNotifier;
  final List<AuthAwareProvider> _authAwareProviders = [];

  AuthManager(this._authNotifier) {
    // Écouter les changements d'authentification
    _authNotifier.addListener(_onAuthStateChanged);
  }

  /// Enregistrer un provider qui a besoin d'être informé des changements d'auth
  void registerAuthAwareProvider(AuthAwareProvider provider) {
    _authAwareProviders.add(provider);
    // Initialiser immédiatement avec le token actuel si disponible
    _updateProviderToken(provider);
  }

  /// Mettre à jour le token d'un provider spécifique
  void _updateProviderToken(AuthAwareProvider provider) {
    final user = _authNotifier.state.user;
    if (user != null) {
      // Récupérer le token depuis les préférences ou l'auth notifier
      provider.initializeAuth();
    }
  }

  /// Appelé quand l'état d'authentification change
  void _onAuthStateChanged() {
    final user = _authNotifier.state.user;
    final isAuthenticated = _authNotifier.isAuthenticated;

    if (isAuthenticated && user != null) {
      // Mettre à jour tous les providers avec le nouveau token
      for (final provider in _authAwareProviders) {
        provider.initializeAuth();
      }
    } else {
      // Déconnecter tous les providers
      for (final provider in _authAwareProviders) {
        provider.updateAuthToken(null);
      }
    }
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}