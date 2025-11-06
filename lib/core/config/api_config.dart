/// Configuration centralisée pour l'API
class ApiConfig {
  /// URL de base de production
  static const String _baseUrl = 'https://mobile.alertcontacts.net';

  /// URL de base pour l'API Laravel (avec /api)
  static String get baseUrl => '$_baseUrl/api';

  /// URL de base pour l'API Laravel (avec /api) - version synchrone
  static String get baseUrlSync => '$_baseUrl/api';

  /// URL de base sans le suffixe /api (pour certains endpoints spéciaux)
  static String get baseUrlWithoutApi => _baseUrl;

  /// URL de base sans le suffixe /api - version synchrone
  static String get baseUrlWithoutApiSync => _baseUrl;

  /// Initialise la configuration API (conservé pour compatibilité)
  static Future<void> initialize() async {
    // Plus besoin d'initialisation complexe, mais on garde la méthode
    // pour éviter de casser le code existant
  }

  /// Timeout par défaut pour les requêtes HTTP (en secondes)
  static const int defaultTimeoutSeconds = 30;

  /// Headers par défaut pour toutes les requêtes
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Méthode utilitaire pour obtenir l'URL complète d'un endpoint
  static String getEndpointUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }

  /// Méthode utilitaire pour obtenir l'URL d'invitation
  static String getInvitationUrl(String token, {String? pin}) {
    var url = '$baseUrlWithoutApi/invitations/accept?t=$token';
    if (pin != null && pin.isNotEmpty) {
      url += '&pin=$pin';
    }
    return url;
  }
}
