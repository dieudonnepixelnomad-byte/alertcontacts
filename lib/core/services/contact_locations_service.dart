// lib/core/services/contact_locations_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/contact_location.dart';
import '../services/prefs_service.dart';
import '../errors/auth_exceptions.dart';

/// Service pour récupérer les positions d'un proche
class ContactLocationsService {
  final PrefsService _prefsService = PrefsService();

  /// Récupérer les positions récentes d'un proche
  Future<List<ContactLocation>> getContactLocations({
    required String contactId,
    int limit = 10,
  }) async {
    try {
      final token = await _prefsService.getBearerToken();
      if (token == null) {
        throw const InvalidCredentialsException();
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/relationships/contact/$contactId/locations');
      final finalUrl = url.replace(queryParameters: {'limit': limit.toString()});
      
      log('ContactLocationsService.getContactLocations: Calling URL: $finalUrl');
      log('ContactLocationsService.getContactLocations: Contact ID: $contactId');
      
      final response = await http.get(
        finalUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('ContactLocationsService.getContactLocations: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Vérifier que la réponse a le bon format
        if (responseData['success'] != true || responseData['data'] == null) {
          throw const UnknownAuthException('Format de réponse API invalide');
        }
        
        final Map<String, dynamic> data = responseData['data'];
        final List<dynamic> locationsJson = data['locations'] ?? [];
        
        final locations = locationsJson
            .map((json) => ContactLocation.fromJson(json as Map<String, dynamic>))
            .toList();

        log('ContactLocationsService.getContactLocations: Retrieved ${locations.length} locations');
        return locations;
      } else if (response.statusCode == 401) {
        throw const InvalidCredentialsException();
      } else if (response.statusCode == 403) {
        throw const UnknownAuthException('Vous n\'avez pas l\'autorisation de voir les positions de ce proche');
      } else if (response.statusCode == 404) {
        throw const UserNotFoundException();
      } else {
        String errorMessage = 'Erreur lors de la récupération des positions';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          log('ContactLocationsService.getContactLocations: Failed to parse error response: $e');
          errorMessage = 'Erreur HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : "Aucun détail d\'erreur"}';
        }
        throw UnknownAuthException(errorMessage);
      }
    } catch (e) {
      log('ContactLocationsService.getContactLocations: Error: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Récupérer la dernière position connue d'un proche
  Future<ContactLocation?> getLastKnownLocation(String contactId) async {
    try {
      final locations = await getContactLocations(
        contactId: contactId,
        limit: 1,
      );
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      log('ContactLocationsService.getLastKnownLocation: Error: $e');
      return null;
    }
  }
}

/// Réponse de l'API pour les positions d'un contact
class ContactLocationsResponse {
  final String contactId;
  final List<ContactLocation> locations;
  final int count;
  final String shareLevel;

  const ContactLocationsResponse({
    required this.contactId,
    required this.locations,
    required this.count,
    required this.shareLevel,
  });

  factory ContactLocationsResponse.fromJson(Map<String, dynamic> json) {
    return ContactLocationsResponse(
      contactId: json['contact_id'] as String,
      locations: (json['locations'] as List)
          .map((location) => ContactLocation.fromJson(location))
          .toList(),
      count: json['count'] as int,
      shareLevel: json['share_level'] as String,
    );
  }
}