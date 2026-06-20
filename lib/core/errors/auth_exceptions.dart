abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException($code): $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Session expirée ou invalide', 'invalid-credentials');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super('Utilisateur introuvable', 'user-not-found');
}

class UserDisabledException extends AuthException {
  const UserDisabledException() 
      : super('Votre compte a été désactivé. Contactez le support.', 'user-disabled');
}

class NetworkException extends AuthException {
  const NetworkException() 
      : super('Problème de connexion. Réessayez.', 'network-error');
}

class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException() 
      : super('Connexion Google annulée', 'google-signin-cancelled');
}

class AppleSignInCancelledException extends AuthException {
  const AppleSignInCancelledException() 
      : super('Connexion Apple annulée', 'apple-signin-cancelled');
}

class AppleSignInFailedException extends AuthException {
  const AppleSignInFailedException(String details) 
      : super('Connexion Apple échouée : $details', 'apple-signin-failed');
}

class InvalidIdTokenException extends AuthException {
  const InvalidIdTokenException() 
      : super('Token d\'authentification invalide', 'invalid-id-token');
}

class SyncErrorException extends AuthException {
  const SyncErrorException() 
      : super('Erreur de synchronisation avec le serveur', 'sync-error');
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  
  @override
  String toString() => 'ServerException: $message';
}

class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException(this.message);
  
  @override
  String toString() => 'SessionExpiredException: $message';
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException() 
      : super('Trop de demandes, réessayez plus tard', 'too-many-requests');
}

class ValidationException extends AuthException {
  final Map<String, List<String>> errors;
  
  const ValidationException(this.errors) 
      : super('Erreurs de validation', 'validation-error');
  
  String get firstError {
    if (errors.isEmpty) return message;
    final firstKey = errors.keys.first;
    final firstErrorList = errors[firstKey];
    return firstErrorList?.isNotEmpty == true ? firstErrorList!.first : message;
  }
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException(String message) 
      : super(message, 'unknown-error');
}