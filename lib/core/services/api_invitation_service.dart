import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/invitation.dart';
import 'invitation_service_interface.dart';
import '../config/api_config.dart';

class ApiInvitationService implements InvitationServiceInterface {
  static String get baseUrl => ApiConfig.baseUrlSync;

  String? _token;

  void setAuthToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Créer une nouvelle invitation
  Future<Invitation> createInvitation({
    required ShareLevel defaultShareLevel,
    List<String>? suggestedZones,
    int? expiresInHours,
    int? maxUses,
    bool? requirePin,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations'),
      headers: _headers,
      body: jsonEncode({
        'default_share_level': _shareLevelToString(defaultShareLevel),
        'suggested_zones': suggestedZones ?? [],
        'expires_in_hours': expiresInHours ?? 24,
        'max_uses': maxUses ?? 1,
        'require_pin': requirePin ?? false,
        'message': message,
      }),
    );

    log('Create Invitation Response: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Invitation.fromCreateResponse(data['data']['invitation']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la création de l\'invitation',
      );
    }
  }

  /// Vérifier la validité d'une invitation
  Future<Invitation> checkInvitation(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invitations/check'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Invitation.fromJson(data['data']['invitation']);
    } else if (response.statusCode == 404) {
      throw InvitationNotFoundException('Invitation introuvable');
    } else if (response.statusCode == 410) {
      throw InvitationExpiredException('Invitation expirée ou déjà utilisée');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la vérification de l\'invitation',
      );
    }
  }

  /// Accepter une invitation
  @override
  Future<void> acceptInvitation({
    required String token,
    required ShareLevel shareLevel,
    required List<String> acceptedZones,
    String? pin,
  }) async {
    log(
      'AcceptationPage: Acceptation Invitation: $token, $shareLevel, $acceptedZones, $pin',
    );

    final response = await http.post(
      Uri.parse('$baseUrl/invitations/accept'),
      headers: _headers,
      body: jsonEncode({
        'token': token,
        'pin': pin,
        'share_level': _shareLevelToString(shareLevel),
        'accept_relation':
            true, // Toujours true dans cette interface simplifiée
        'accepted_zones': acceptedZones,
      }),
    );

    log('AcceptationPage: Acceptation Response: ${response.body}');

    if (response.statusCode == 200) {
      // Succès
      return;
    } else if (response.statusCode == 404) {
      throw InvitationNotFoundException('Invitation introuvable');
    } else if (response.statusCode == 410) {
      throw InvitationExpiredException('Invitation expirée ou déjà utilisée');
    } else if (response.statusCode == 422) {
      final error = jsonDecode(response.body);
      if (error['message']?.contains('PIN') == true) {
        throw InvalidPinException('Code PIN incorrect');
      } else if (error['message']?.contains('refusée') == true) {
        throw InvitationRefusedException('Invitation refusée');
      } else {
        throw ValidationException(error['message'] ?? 'Données invalides');
      }
    } else if (response.statusCode == 409) {
      throw RelationAlreadyExistsException(
        'Une relation existe déjà entre vous',
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de l\'acceptation de l\'invitation',
      );
    }
  }

  /// Lister les invitations créées par l'utilisateur
  Future<List<Invitation>> getMyInvitations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/invitations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final invitationsJson = data['data']['invitations'] as List;
      return invitationsJson.map((json) => Invitation.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la récupération des invitations',
      );
    }
  }

  /// Annuler/supprimer une invitation
  Future<void> deleteInvitation(String invitationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/invitations/$invitationId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // Succès
      return;
    } else if (response.statusCode == 404) {
      throw InvitationNotFoundException('Invitation introuvable');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la suppression de l\'invitation',
      );
    }
  }

  String _shareLevelToString(ShareLevel shareLevel) {
    switch (shareLevel) {
      case ShareLevel.realtime:
        return 'realtime';
      case ShareLevel.alertOnly:
        return 'alert_only';
      case ShareLevel.none:
        return 'none';
    }
  }
}

// Exceptions spécifiques
class InvitationNotFoundException implements Exception {
  final String message;
  InvitationNotFoundException(this.message);
}

class InvitationExpiredException implements Exception {
  final String message;
  InvitationExpiredException(this.message);
}

class InvitationRefusedException implements Exception {
  final String message;
  InvitationRefusedException(this.message);
}

class InvalidPinException implements Exception {
  final String message;
  InvalidPinException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class RelationAlreadyExistsException implements Exception {
  final String message;
  RelationAlreadyExistsException(this.message);
}
