import 'package:flutter/foundation.dart';
import '../services/prefs_service.dart';

/// Mixin pour les providers qui ont besoin d'être informés des changements d'authentification
mixin AuthAwareProvider on ChangeNotifier {
  final PrefsService _prefs = PrefsService();
  String? _currentToken;

  /// Initialiser le provider avec le token actuel
  Future<void> initializeAuth() async {
    final token = await _prefs.getBearerToken();
    if (token != null && token != _currentToken) {
      _currentToken = token;
      onAuthTokenChanged(token);
    }
  }

  /// Mettre à jour le token d'authentification
  void updateAuthToken(String? token) {
    if (token != _currentToken) {
      _currentToken = token;
      onAuthTokenChanged(token);
    }
  }

  /// Méthode à implémenter par les providers qui utilisent ce mixin
  void onAuthTokenChanged(String? token);

  /// Obtenir le token actuel
  String? get currentToken => _currentToken;

  /// Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => _currentToken != null;
}