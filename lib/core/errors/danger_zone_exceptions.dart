// lib/core/errors/danger_zone_exceptions.dart

abstract class DangerZoneException implements Exception {
  final String message;
  final String code;

  const DangerZoneException(this.message, this.code);

  @override
  String toString() => 'DangerZoneException($code): $message';
}

class ZoneNotFoundException extends DangerZoneException {
  const ZoneNotFoundException() 
      : super('Zone de danger introuvable', 'zone-not-found');
}

class AlreadyConfirmedException extends DangerZoneException {
  const AlreadyConfirmedException() 
      : super('Vous avez déjà confirmé cette zone', 'already-confirmed');
}

class AlreadyReportedException extends DangerZoneException {
  const AlreadyReportedException() 
      : super('Vous avez déjà signalé cette zone', 'already-reported');
}

class ZoneExpiredException extends DangerZoneException {
  const ZoneExpiredException() 
      : super('Cette zone a expiré', 'zone-expired');
}

class DuplicateZoneException extends DangerZoneException {
  final String existingZoneId;
  
  const DuplicateZoneException(this.existingZoneId) 
      : super('Une zone similaire existe déjà à proximité', 'duplicate-zone');
}

class InvalidLocationException extends DangerZoneException {
  const InvalidLocationException() 
      : super('Localisation invalide', 'invalid-location');
}

class PermissionDeniedException extends DangerZoneException {
  const PermissionDeniedException() 
      : super('Permission refusée', 'permission-denied');
}