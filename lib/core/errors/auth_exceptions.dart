abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException($code): $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() 
      : super('Vérifiez vos identifiants', 'invalid-credentials');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() 
      : super('Utilisateur introuvable', 'user-not-found');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() 
      : super('Un compte existe déjà avec cet email', 'email-already-in-use');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() 
      : super('Le mot de passe doit contenir au moins 8 caractères', 'weak-password');
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException() 
      : super('Veuillez vérifier votre email avant de continuer', 'email-not-verified');
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