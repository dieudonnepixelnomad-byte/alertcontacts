// lib/core/errors/api_exceptions.dart

/// Exception de base pour toutes les erreurs API
abstract class ApiException implements Exception {
  const ApiException(this.message);
  
  final String message;
  
  @override
  String toString() => 'ApiException: $message';
}

/// Exception réseau (pas de connexion internet)
class NetworkException extends ApiException {
  const NetworkException([String? message]) 
      : super(message ?? 'Aucune connexion internet disponible');
}

/// Exception pour les requêtes malformées (400)
class BadRequestException extends ApiException {
  const BadRequestException([String? message]) 
      : super(message ?? 'Requête invalide');
}

/// Exception pour l'authentification échouée (401)
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String? message]) 
      : super(message ?? 'Authentification requise');
}

/// Exception pour l'accès interdit (403)
class ForbiddenException extends ApiException {
  const ForbiddenException([String? message]) 
      : super(message ?? 'Accès interdit');
}

/// Exception pour les ressources non trouvées (404)
class NotFoundException extends ApiException {
  const NotFoundException([String? message]) 
      : super(message ?? 'Ressource non trouvée');
}

/// Exception pour les erreurs de validation (422)
class ValidationException extends ApiException {
  const ValidationException(String message, [this.errors]) : super(message);
  
  final Map<String, dynamic>? errors;
  
  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return 'ValidationException: $message ($errorMessages)';
    }
    return 'ValidationException: $message';
  }
}

/// Exception pour trop de requêtes (429)
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException([String? message]) 
      : super(message ?? 'Trop de requêtes, veuillez réessayer plus tard');
}

/// Exception pour les erreurs serveur (500)
class ServerException extends ApiException {
  const ServerException([String? message]) 
      : super(message ?? 'Erreur interne du serveur');
}

/// Exception pour les erreurs API inconnues
class UnknownApiException extends ApiException {
  const UnknownApiException([String? message]) 
      : super(message ?? 'Erreur API inconnue');
}

/// Exception pour les timeouts
class TimeoutException extends ApiException {
  const TimeoutException([String? message]) 
      : super(message ?? 'Délai d\'attente dépassé');
}

/// Exception pour les erreurs de parsing JSON
class ParseException extends ApiException {
  const ParseException([String? message]) 
      : super(message ?? 'Erreur de parsing des données');
}