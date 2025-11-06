import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/danger_zone.dart';
import '../errors/auth_exceptions.dart';
import '../errors/danger_zone_exceptions.dart';

class ApiDangerZoneService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiDangerZoneService({required this.baseUrl, http.Client? client})
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

  /// Récupérer les zones de danger dans un rayon donné
  Future<List<DangerZone>> getDangerZones({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    try {
      log('ApiDangerZoneService.getDangerZones: Fetching danger zones');
      
      final uri = Uri.parse('$baseUrl/danger-zones').replace(
        queryParameters: {
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
          if (radiusKm != null) 'radius_km': radiusKm.toString(),
        },
      );
      
      final response = await _client.get(uri, headers: _headers);

      log('ApiDangerZoneService.getDangerZones: Response status = ${response.statusCode}');

      final data = _handleResponse(response);
      final zones = (data as List)
          .map((zoneJson) => DangerZone.fromJson(zoneJson as Map<String, dynamic>))
          .toList();
      
      log('ApiDangerZoneService.getDangerZones: Retrieved ${zones.length} zones');
      return zones;
    } on SocketException catch (e) {
      log('ApiDangerZoneService.getDangerZones: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.getDangerZones: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Créer une nouvelle zone de danger
  Future<DangerZone> createDangerZone(DangerZone zone) async {
    try {
      log('ApiDangerZoneService.createDangerZone: Creating zone ${zone.title}');
      
      final payload = {
        'title': zone.title,
        'description': zone.description,
        'center': {
          'lat': zone.center.lat,
          'lng': zone.center.lng,
        },
        'radius_m': zone.radiusMeters,
        'severity': zone.severity.name,
        'danger_type': zone.dangerType.value,
      };
      
      final response = await _client.post(
        Uri.parse('$baseUrl/danger-zones'),
        headers: _headers,
        body: jsonEncode(payload),
      );

      log('ApiDangerZoneService.createDangerZone: Response status = ${response.statusCode}');

      final data = _handleResponse(response);
      final createdZone = DangerZone.fromJson(data);
      
      log('ApiDangerZoneService.createDangerZone: Zone created successfully: ${createdZone.id}');
      return createdZone;
    } on SocketException catch (e) {
      log('ApiDangerZoneService.createDangerZone: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.createDangerZone: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Confirmer une zone de danger
  Future<DangerZone> confirmDangerZone(String zoneId) async {
    try {
      log('ApiDangerZoneService.confirmDangerZone: Confirming zone $zoneId');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/danger-zones/$zoneId/confirm'),
        headers: _headers,
      );

      log('ApiDangerZoneService.confirmDangerZone: Response status = ${response.statusCode}');

      final data = _handleResponse(response);
      final updatedZone = DangerZone.fromJson(data);
      
      log('ApiDangerZoneService.confirmDangerZone: Zone confirmed successfully');
      return updatedZone;
    } on SocketException catch (e) {
      log('ApiDangerZoneService.confirmDangerZone: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.confirmDangerZone: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Signaler un abus pour une zone de danger
  Future<void> reportAbuse(String zoneId, String reason) async {
    try {
      log('ApiDangerZoneService.reportAbuse: Reporting abuse for zone $zoneId');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/danger-zones/$zoneId/report-abuse'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      log('ApiDangerZoneService.reportAbuse: Response status = ${response.statusCode}');

      _handleResponse(response);
      log('ApiDangerZoneService.reportAbuse: Abuse reported successfully');
    } on SocketException catch (e) {
      log('ApiDangerZoneService.reportAbuse: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.reportAbuse: Exception: $e');
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
  Exception _mapApiError(Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>?;
    if (error == null) {
      return UnknownAuthException(body.toString());
    }

    final code = error['code'] as String?;
    final message = error['message'] as String?;

    switch (code) {
      case 'ZONE_NOT_FOUND':
        return const ZoneNotFoundException();
      case 'INVALID_ZONE_DATA':
        return UnknownAuthException('Données de zone invalides');
      case 'ALREADY_CONFIRMED':
        return const AlreadyConfirmedException();
      case 'SYNC_ERROR':
        return const SyncErrorException();
      case 'TOO_MANY_REQUESTS':
        return const TooManyRequestsException();
      default:
        return UnknownAuthException(message ?? 'Erreur API inconnue');
    }
  }



  /// Récupérer une zone de danger spécifique par ID
  Future<DangerZone> getDangerZoneById(String zoneId) async {
    try {
      log('ApiDangerZoneService.getDangerZoneById: Fetching zone $zoneId');
      
      final uri = Uri.parse('$baseUrl/danger-zones/$zoneId');
      final response = await _client.get(uri, headers: _headers);

      log('ApiDangerZoneService.getDangerZoneById: Response status = ${response.statusCode}');

      final data = _handleResponse(response);
      final zone = DangerZone.fromJson(data as Map<String, dynamic>);

      log('ApiDangerZoneService.getDangerZoneById: Zone retrieved successfully');
      return zone;
    } catch (e) {
      log('ApiDangerZoneService.getDangerZoneById: Error = $e');
      rethrow;
    }
  }

  /// Supprimer une zone de danger
  Future<void> deleteDangerZone(String zoneId) async {
    try {
      log('ApiDangerZoneService.deleteDangerZone: Deleting zone $zoneId');
      
      final uri = Uri.parse('$baseUrl/danger-zones/$zoneId');
      final response = await _client.delete(uri, headers: _headers);

      log('ApiDangerZoneService.deleteDangerZone: Response status = ${response.statusCode}');

      _handleResponse(response);
      log('ApiDangerZoneService.deleteDangerZone: Zone deleted successfully');
    } catch (e) {
      log('ApiDangerZoneService.deleteDangerZone: Error = $e');
      rethrow;
    }
  }

  /// Vérifier s'il existe des zones similaires dans un rayon donné
  Future<List<DangerZone>> checkForDuplicates({
    required double lat,
    required double lng,
    required double radiusMeters,
    String? excludeZoneId,
  }) async {
    try {
      log('ApiDangerZoneService.checkForDuplicates: Checking for duplicates at ($lat, $lng) within ${radiusMeters}m');
      
      final body = {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius': radiusMeters.toString(),
      };
      
      if (excludeZoneId != null) {
        body['exclude'] = excludeZoneId;
      }
      
      final response = await _client.post(
        Uri.parse('$baseUrl/danger-zones/check-duplicates'),
        headers: _headers,
        body: jsonEncode(body),
      );

      log('ApiDangerZoneService.checkForDuplicates: Response status = ${response.statusCode}');
      log('ApiDangerZoneService.checkForDuplicates: Response body = ${response.body}');

      final data = _handleResponse(response);
      log('ApiDangerZoneService.checkForDuplicates: Parsed data = $data');
      log('ApiDangerZoneService.checkForDuplicates: Data type = ${data.runtimeType}');
      
      // _handleResponse retourne directement body['data'], qui est déjà la liste des zones
      final zones = (data as List)
          .map((json) => DangerZone.fromJson(json))
          .toList();
      
      log('ApiDangerZoneService.checkForDuplicates: Found ${zones.length} potential duplicates');
      return zones;
    } on SocketException catch (e) {
      log('ApiDangerZoneService.checkForDuplicates: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.checkForDuplicates: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Nettoyer les zones expirées (plus de 30 jours)
  Future<int> cleanupExpiredZones() async {
    try {
      log('ApiDangerZoneService.cleanupExpiredZones: Cleaning up expired zones');
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/danger-zones/cleanup-expired'),
        headers: _headers,
      );

      log('ApiDangerZoneService.cleanupExpiredZones: Response status = ${response.statusCode}');

      final data = _handleResponse(response);
      final deletedCount = data['deleted_count'] as int? ?? 0;
      
      log('ApiDangerZoneService.cleanupExpiredZones: Deleted $deletedCount expired zones');
      return deletedCount;
    } on SocketException catch (e) {
      log('ApiDangerZoneService.cleanupExpiredZones: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiDangerZoneService.cleanupExpiredZones: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Vérifier si une zone est expirée (plus de 30 jours)
  bool isZoneExpired(DangerZone zone) {
    final now = DateTime.now();
    final expirationDate = zone.lastReportAt.add(const Duration(days: 30));
    return now.isAfter(expirationDate);
  }

  /// Filtrer les zones expirées d'une liste
  List<DangerZone> filterExpiredZones(List<DangerZone> zones) {
    return zones.where((zone) => !isZoneExpired(zone)).toList();
  }

  /// Nettoyer les ressources
  void dispose() {
    _client.close();
  }
}