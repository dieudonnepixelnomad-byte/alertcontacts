import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/contact_relation.dart';
import '../models/invitation.dart';
import '../config/api_config.dart';

class ApiRelationshipService {
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

  /// Lister toutes les relations de l'utilisateur
  Future<List<ContactRelation>> getMyRelationships() async {
    log('Appel à getMyRelationships');
    final response = await http.get(
      Uri.parse('$baseUrl/relationships'),
      headers: _headers,
    );

    log('Réponse getMyRelationships: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final relationshipsJson = data['data']['relationships'] as List;
      return relationshipsJson
          .map((json) => ContactRelation.fromJson(json))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la récupération des relations',
      );
    }
  }

  /// Obtenir les détails d'une relation spécifique
  Future<ContactRelation> getRelationship(String relationshipId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/relationships/$relationshipId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContactRelation.fromJson(data['data']['relationship']);
    } else if (response.statusCode == 404) {
      throw RelationshipNotFoundException('Relation introuvable');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la récupération de la relation',
      );
    }
  }

  /// Mettre à jour les paramètres de partage d'une relation
  Future<ContactRelation> updateShareLevel({
    required String relationshipId,
    required ShareLevel shareLevel,
    required bool canSeeMe,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/relationships/$relationshipId/share-level'),
      headers: _headers,
      body: jsonEncode({
        'share_level': _shareLevelToString(shareLevel),
        'can_see_me': canSeeMe,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ContactRelation.fromJson(data['data']['relationship']);
    } else if (response.statusCode == 404) {
      throw RelationshipNotFoundException('Relation introuvable');
    } else if (response.statusCode == 422) {
      final error = jsonDecode(response.body);
      throw ValidationException(error['message'] ?? 'Données invalides');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la mise à jour des paramètres',
      );
    }
  }

  /// Supprimer une relation (retirer un proche)
  Future<void> deleteRelationship(String relationshipId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/relationships/$relationshipId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // Succès
      return;
    } else if (response.statusCode == 404) {
      throw RelationshipNotFoundException('Relation introuvable');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la suppression de la relation',
      );
    }
  }

  /// Obtenir les statistiques des relations
  Future<RelationStats> getRelationshipStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/relationships/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RelationStats.fromJson(data['data']['stats']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la récupération des statistiques',
      );
    }
  }

  /// Rechercher des utilisateurs pour les inviter
  Future<List<Contact>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/relationships/search-users?query=${Uri.encodeComponent(query)}',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usersJson = data['data']['users'] as List;
      return usersJson.map((json) => Contact.fromJson(json)).toList();
    } else if (response.statusCode == 422) {
      final error = jsonDecode(response.body);
      throw ValidationException(
        error['message'] ?? 'Requête de recherche invalide',
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la recherche d\'utilisateurs',
      );
    }
  }

  /// Filtrer les relations par statut
  Future<List<ContactRelation>> getRelationshipsByStatus(
    RelationStatus status,
  ) async {
    final allRelations = await getMyRelationships();
    return allRelations.where((relation) => relation.status == status).toList();
  }

  /// Obtenir uniquement les relations acceptées
  Future<List<ContactRelation>> getAcceptedRelationships() async {
    return getRelationshipsByStatus(RelationStatus.accepted);
  }

  /// Obtenir uniquement les relations en attente
  Future<List<ContactRelation>> getPendingRelationships() async {
    return getRelationshipsByStatus(RelationStatus.pending);
  }

  /// Obtenir les relations avec partage en temps réel
  Future<List<ContactRelation>> getRealtimeSharingRelationships() async {
    final acceptedRelations = await getAcceptedRelationships();
    return acceptedRelations
        .where((relation) => relation.isRealtimeSharing)
        .toList();
  }

  /// Obtenir les relations avec partage d'alertes uniquement
  Future<List<ContactRelation>> getAlertOnlySharingRelationships() async {
    final acceptedRelations = await getAcceptedRelationships();
    return acceptedRelations
        .where((relation) => relation.isAlertOnlySharing)
        .toList();
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

  /// Obtenir les zones assignables pour un contact
  Future<List<AssignableZone>> getAssignableZones(String contactId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/proches/$contactId/zones'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('Response data: $data', name: 'ApiRelationshipService');

        if (data['success'] == true) {
          // La structure de réponse est: { success: true, data: { contact_id: "...", zones: [...] } }
          if (data['data'] != null && data['data']['zones'] != null) {
            final zones = data['data']['zones'] as List;
            return zones.map((zone) => AssignableZone.fromJson(zone)).toList();
          } else {
            throw Exception('Aucune donnée de zones trouvée dans la réponse');
          }
        } else {
          throw Exception(
            data['message'] ?? 'Erreur lors du chargement des zones',
          );
        }
      } else if (response.statusCode == 404) {
        throw RelationshipNotFoundException('Contact non trouvé');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Erreur lors du chargement des zones',
        );
      }
    } catch (e) {
      log('Erreur getAssignableZones: $e', name: 'ApiRelationshipService');
      rethrow;
    }
  }

  /// Assigner une zone à un contact
  Future<void> assignZone(String contactId, String zoneId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/proches/$contactId/zones/$zoneId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors de l\'assignation');
        }
      } else if (response.statusCode == 404) {
        throw RelationshipNotFoundException('Contact ou zone non trouvé');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Données invalides');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'assignation');
      }
    } catch (e) {
      log('Erreur assignZone: $e', name: 'ApiRelationshipService');
      rethrow;
    }
  }

  /// Retirer l'assignation d'une zone à un contact
  Future<void> unassignZone(String contactId, String zoneId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/proches/$contactId/zones/$zoneId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors de la suppression');
        }
      } else if (response.statusCode == 404) {
        throw RelationshipNotFoundException('Contact ou zone non trouvé');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      log('Erreur unassignZone: $e', name: 'ApiRelationshipService');
      rethrow;
    }
  }

  /// Changer le statut d'une zone assignée (activer/pause)
  Future<void> toggleZoneAssignment(
    String contactId,
    String zoneId,
    String status,
  ) async {
    try {
      // Convertir le status string en boolean pour correspondre à l'API Laravel
      final isActive = status == 'active';
      
      final response = await http.patch(
        Uri.parse('$baseUrl/proches/$contactId/zones/$zoneId'),
        headers: _headers,
        body: jsonEncode({'is_active': isActive}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors de la modification');
        }
      } else if (response.statusCode == 404) {
        throw RelationshipNotFoundException('Contact ou zone non trouvé');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Statut invalide');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      log('Erreur toggleZoneAssignment: $e', name: 'ApiRelationshipService');
      rethrow;
    }
  }
}

// Modèle pour les zones assignables
class AssignableZone {
  final String id;
  final String name;
  final String icon;
  final double lat;
  final double lng;
  final double radiusM;
  final bool isAssigned;
  final String? assignmentStatus;

  AssignableZone({
    required this.id,
    required this.name,
    required this.icon,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.isAssigned,
    this.assignmentStatus,
  });

  factory AssignableZone.fromJson(Map<String, dynamic> json) {
    // Gérer assignment_status qui peut être bool ou String
    String? assignmentStatus;
    final assignmentValue = json['assignment_status'];
    if (assignmentValue is bool) {
      // Convertir boolean vers 'active'/'paused'
      assignmentStatus = assignmentValue ? 'active' : 'paused';
    } else if (assignmentValue is String) {
      assignmentStatus = assignmentValue;
    } else {
      assignmentStatus = null;
    }

    return AssignableZone(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'home',
      lat: (json['center']?['lat'] ?? 0.0).toDouble(),
      lng: (json['center']?['lng'] ?? 0.0).toDouble(),
      radiusM: (json['radius_m'] ?? 0.0).toDouble(),
      isAssigned: json['is_assigned'] ?? false,
      assignmentStatus: assignmentStatus,
    );
  }
}

// Exceptions spécifiques
class RelationshipNotFoundException implements Exception {
  final String message;
  RelationshipNotFoundException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
