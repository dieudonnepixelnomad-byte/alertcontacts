import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/safe_zone.dart';
import '../errors/auth_exceptions.dart';

class ApiSafeZoneService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiSafeZoneService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Headers par défaut pour les requêtes API
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };

  /// Définir le token Bearer
  void setBearerToken(String? token) {
    _bearerToken = token;
  }

  /// Créer une nouvelle zone de sécurité
  Future<SafeZone> createSafeZone(SafeZone zone) async {
    try {
      log('ApiSafeZoneService.createSafeZone: Creating zone ${zone.name}');

      // Préparer le payload selon le format attendu par Laravel
      final Map<String, dynamic> payload = {
        'name': zone.name,
        'icon': zone.iconKey,
        'center': {'lat': zone.center.lat, 'lng': zone.center.lng},
        'radius_m': zone.radiusMeters,
      };

      // Ajouter les contact_ids si des membres sont spécifiés
      if (zone.memberIds.isNotEmpty) {
        payload['contact_ids'] = zone.memberIds;
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/safe-zones'),
        headers: _headers,
        body: jsonEncode(payload),
      );

      log(
        'ApiSafeZoneService.createSafeZone: Response status = ${response.statusCode}',
      );
      log(
        'ApiSafeZoneService.createSafeZone: Response body = ${response.body}',
      );

      final data = _handleResponse(response);
      final createdZone = SafeZone.fromJson(_mapBackendToModel(data));

      log(
        'ApiSafeZoneService.createSafeZone: Zone created successfully: ${createdZone.id}',
      );
      return createdZone;
    } on SocketException catch (e) {
      log('ApiSafeZoneService.createSafeZone: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiSafeZoneService.createSafeZone: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Récupérer toutes les zones de sécurité de l'utilisateur
  Future<List<SafeZone>> getSafeZones() async {
    try {
      log('ApiSafeZoneService.getSafeZones: Fetching user safe zones');

      final response = await _client.get(
        Uri.parse('$baseUrl/safe-zones'),
        headers: _headers,
      );

      log(
        'ApiSafeZoneService.getSafeZones: Response status = ${response.statusCode}',
      );

      final data = _handleResponse(response);

      log('ApiSafeZoneService.getSafeZones: Data Response $data');

      final zones = (data as List)
          .map(
            (zoneJson) => SafeZone.fromJson(zoneJson as Map<String, dynamic>),
          )
          .toList();

      log('ApiSafeZoneService.getSafeZones: Retrieved ${zones.length} zones');
      return zones;
    } on SocketException catch (e) {
      log('ApiSafeZoneService.getSafeZones: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiSafeZoneService.getSafeZones: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Mettre à jour une zone de sécurité
  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    try {
      log('ApiSafeZoneService.updateSafeZone: Updating zone ${zone.id}');

      final response = await _client.put(
        Uri.parse('$baseUrl/safe-zones/${zone.id}'),
        headers: _headers,
        body: jsonEncode({
          'name': zone.name,
          'icon_key': zone.iconKey,
          'center': zone.center.toJson(),
          'radius_meters': zone.radiusMeters,
          'address': zone.address,
          'member_ids': zone.memberIds,
        }),
      );

      log(
        'ApiSafeZoneService.updateSafeZone: Response status = ${response.statusCode}',
      );

      final data = _handleResponse(response);
      final updatedZone = SafeZone.fromJson(data);

      log('ApiSafeZoneService.updateSafeZone: Zone updated successfully');
      return updatedZone;
    } on SocketException catch (e) {
      log('ApiSafeZoneService.updateSafeZone: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiSafeZoneService.updateSafeZone: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Supprimer une zone de sécurité
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      log('ApiSafeZoneService.deleteSafeZone: Deleting zone $zoneId');

      final response = await _client.delete(
        Uri.parse('$baseUrl/safe-zones/$zoneId'),
        headers: _headers,
      );

      log(
        'ApiSafeZoneService.deleteSafeZone: Response status = ${response.statusCode}',
      );

      _handleResponse(response);
      log('ApiSafeZoneService.deleteSafeZone: Zone deleted successfully');
    } on SocketException catch (e) {
      log('ApiSafeZoneService.deleteSafeZone: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiSafeZoneService.deleteSafeZone: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Gérer la réponse HTTP et mapper les erreurs
  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['success'] == true) {
        return body['data'];
      } else {
        throw _mapApiError(body);
      }
    }

    // Gestion des codes d'erreur HTTP
    switch (response.statusCode) {
      case 401:
        throw const InvalidCredentialsException();
      case 403:
        throw const UserDisabledException();
      case 422:
        // Gestion spéciale des erreurs de validation
        if (body['errors'] != null) {
          final errors = Map<String, List<String>>.from(
            (body['errors'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value as List)),
            ),
          );
          throw ValidationException(errors);
        }
        throw _mapApiError(body);
      case 429:
        throw const TooManyRequestsException();
      case 500:
      case 502:
      case 503:
      case 504:
        throw const SyncErrorException();
      default:
        throw UnknownAuthException(
          'HTTP ${response.statusCode}: ${response.body}',
        );
    }
  }

  /// Mapper les erreurs de l'API vers nos exceptions
  AuthException _mapApiError(Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>?;
    if (error == null) {
      return UnknownAuthException(body.toString());
    }

    final code = error['code'] as String?;
    final message = error['message'] as String?;

    switch (code) {
      case 'ZONE_NOT_FOUND':
        return UnknownAuthException('Zone non trouvée');
      case 'INVALID_ZONE_DATA':
        return UnknownAuthException('Données de zone invalides');
      case 'SYNC_ERROR':
        return const SyncErrorException();
      case 'TOO_MANY_REQUESTS':
        return const TooManyRequestsException();
      default:
        return UnknownAuthException(message ?? 'Erreur API inconnue');
    }
  }

  /// Mapper la réponse du backend Laravel vers le format du modèle mobile
  Map<String, dynamic> _mapBackendToModel(Map<String, dynamic> backendData) {
    return {
      'id': backendData['id'].toString(),
      'name': backendData['name'],
      'icon_key': backendData['icon'] ?? 'home',
      'center': {
        'lat': backendData['center']?['lat'] ?? 0.0,
        'lng': backendData['center']?['lng'] ?? 0.0,
      },
      'radius_meters': backendData['radius_m']?.toDouble() ?? 100.0,
      'address': backendData['address'],
      'member_ids': backendData['contact_ids'] ?? [],
      'created_at': backendData['created_at'],
      'updated_at': backendData['updated_at'],
    };
  }

  /// Nettoyer les ressources
  void dispose() {
    _client.close();
  }
}
