// lib/core/fakes/fake_invitation_service.dart
import 'dart:async';

enum ShareLevel { realtime, alertOnly, none }

class InviteInfo {
  final String inviterName;
  final String inviterAvatarUrl;
  final DateTime expiresAt;
  final int remainingUses; // -1 => illimité
  final bool requiresPin;
  final ShareLevel defaultLevel;
  final List<String>
  suggestedZones; // zones auxquelles l’inviteur souhaite vous affecter
  InviteInfo({
    required this.inviterName,
    required this.inviterAvatarUrl,
    required this.expiresAt,
    required this.remainingUses,
    required this.requiresPin,
    required this.defaultLevel,
    required this.suggestedZones,
  });
}

sealed class InviteCheckResult {}

class InviteValid extends InviteCheckResult {
  final InviteInfo info;
  InviteValid(this.info);
}

class InviteInvalid extends InviteCheckResult {
  final String reason;
  InviteInvalid(this.reason);
}

class FakeInvitationService {
  // Vérifie le token et renvoie les infos de l’invitation
  Future<InviteCheckResult> checkToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (token.isEmpty) return InviteInvalid('Lien invalide');
    if (token.startsWith('x')) return InviteInvalid('Invitation expirée');
    if (token.startsWith('u')) return InviteInvalid('Invitation déjà utilisée');

    // FAKE : on “décide” si un PIN est requis selon la longueur
    final requiresPin = token.length % 2 == 0;

    return InviteValid(
      InviteInfo(
        inviterName: 'Marie',
        inviterAvatarUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        remainingUses: 1,
        requiresPin: requiresPin,
        defaultLevel: ShareLevel.alertOnly,
        suggestedZones: const ['Maison', 'École'],
      ),
    );
  }

  // Tente de “consommer” l’invitation
  Future<(bool ok, String? error)> redeem({
    required String token,
    required ShareLevel chosenLevel,
    String? pin,
    required bool acceptRelation,
    required List<String> acceptedZones,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));

    if (!acceptRelation) {
      return (false, 'Vous devez accepter la relation pour continuer.');
    }
    // FAKE: si un pin est attendu, on exige '1234'
    final needsPin = token.length % 2 == 0;
    if (needsPin && pin != '1234') return (false, 'Code PIN incorrect');

    // FAKE: si token commence par 'b' => raté réseau
    if (token.startsWith('b')) return (false, 'Erreur réseau. Réessayez.');

    return (true, null);
  }
}
