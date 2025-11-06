// lib/core/services/invitation_service_interface.dart
import '../models/invitation.dart';

/// Interface commune pour les services d'invitation
abstract class InvitationServiceInterface {
  void setAuthToken(String token);
  
  Future<Invitation> createInvitation({
    required ShareLevel defaultShareLevel,
    List<String>? suggestedZones,
    int? expiresInHours,
    int? maxUses,
    bool? requirePin,
    String? message,
  });
  
  Future<Invitation> checkInvitation(String token);
  
  Future<void> acceptInvitation({
    required String token,
    required ShareLevel shareLevel,
    required List<String> acceptedZones,
    String? pin,
  });
  
  Future<List<Invitation>> getMyInvitations();
  
  Future<void> deleteInvitation(String id);
}