import 'dart:convert';
import 'dart:developer';
import '../config/api_config.dart';
import '../models/ignored_danger_zone.dart';
import 'package:http/http.dart' as http;

/// Service pour gérer les zones de danger ignorées via l'API
class ApiIgnoredDangerZonesService {
  String? _bearerToken;

  ApiIgnoredDangerZonesService();

  /// Définir le token d'authentification
  void setBearerToken(String? token) {
    _bearerToken = token;
    log('ApiIgnoredDangerZonesService: Bearer token set');
  }

  /// Obtenir les en-têtes HTTP avec authentification
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };

  /// Ignorer une zone de danger
  Future<IgnoredDangerZone> ignoreDangerZone({
    required String dangerZoneId,
    String? reason,
    int? hours,
  }) async {
    try {
      log(
        'ApiIgnoredDangerZonesService.ignoreDangerZone: Ignoring zone $dangerZoneId',
      );

      final body = {
        'danger_zone_id': int.parse(dangerZoneId),
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ignored-danger-zones/ignore'),
        headers: _headers,
        body: jsonEncode(body),
      );

      log(
        'ApiIgnoredDangerZonesService.ignoreDangerZone: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception('Non autorisé');
      }

      if (response.statusCode == 409) {
        throw Exception('Cette zone est déjà ignorée');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'ignorage');
      }

      final responseData = jsonDecode(response.body);
      final ignoredZoneData = responseData['data'];

      log(
        'ApiIgnoredDangerZonesService.ignoreDangerZone: Zone ignored successfully',
      );

      return IgnoredDangerZone.fromJson(ignoredZoneData);
    } catch (e) {
      log('ApiIgnoredDangerZonesService.ignoreDangerZone: Error: $e');
      rethrow;
    }
  }

  /// Réactiver les alertes pour une zone de danger
  Future<void> reactivateDangerZone(String dangerZoneId) async {
    try {
      log(
        'ApiIgnoredDangerZonesService.reactivateDangerZone: Reactivating zone $dangerZoneId',
      );

      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/ignored-danger-zones/$dangerZoneId/reactivate',
        ),
        headers: _headers,
      );

      log(
        'ApiIgnoredDangerZonesService.reactivateDangerZone: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception('Non autorisé');
      }

      if (response.statusCode == 404) {
        throw Exception('Cette zone n\'est pas ignorée');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la réactivation',
        );
      }

      log(
        'ApiIgnoredDangerZonesService.reactivateDangerZone: Zone reactivated successfully',
      );
    } catch (e) {
      log('ApiIgnoredDangerZonesService.reactivateDangerZone: Error: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les zones ignorées par l'utilisateur
  Future<List<IgnoredDangerZone>> getIgnoredDangerZones() async {
    try {
      log(
        'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Fetching ignored zones',
      );

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ignored-danger-zones'),
        headers: _headers,
      );

      log(
        'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception('Non autorisé');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la récupération',
        );
      }

      final responseData = jsonDecode(response.body);
      final List<dynamic> zonesData = responseData['data'];

      final zones = <IgnoredDangerZone>[];
      for (final zoneData in zonesData) {
        try {
          log(
            'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Parsing zone data: $zoneData',
          );
          zones.add(IgnoredDangerZone.fromJson(zoneData));
        } catch (e) {
          log(
            'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Error parsing zone: $e',
          );
          log(
            'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Problematic zone data: $zoneData',
          );
        }
      }

      log(
        'ApiIgnoredDangerZonesService.getIgnoredDangerZones: Retrieved ${zones.length} ignored zones',
      );
      return zones;
    } catch (e) {
      log('ApiIgnoredDangerZonesService.getIgnoredDangerZones: Error: $e');
      rethrow;
    }
  }

  /// Prolonger l'expiration d'une zone ignorée
  Future<void> extendIgnoredZone(String dangerZoneId) async {
    try {
      log(
        'ApiIgnoredDangerZonesService.extendIgnoredZone: Extending zone $dangerZoneId',
      );

      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/ignored-danger-zones/$dangerZoneId/extend',
        ),
        headers: _headers,
      );

      log(
        'ApiIgnoredDangerZonesService.extendIgnoredZone: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception('Non autorisé');
      }

      if (response.statusCode == 404) {
        throw Exception('Cette zone n\'est pas ignorée');
      }

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la prolongation',
        );
      }

      log(
        'ApiIgnoredDangerZonesService.extendIgnoredZone: Zone extended successfully',
      );
    } catch (e) {
      log('ApiIgnoredDangerZonesService.extendIgnoredZone: Error: $e');
      rethrow;
    }
  }

  /// Vérifier si une zone est ignorée
  Future<bool> isZoneIgnored(String dangerZoneId) async {
    try {
      log(
        'ApiIgnoredDangerZonesService.isZoneIgnored: Checking zone $dangerZoneId',
      );

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/ignored-danger-zones/$dangerZoneId/check',
        ),
        headers: _headers,
      );

      log(
        'ApiIgnoredDangerZonesService.isZoneIgnored: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 401) {
        throw Exception('Non autorisé');
      }

      if (response.statusCode != 200) {
        return false;
      }

      final responseData = jsonDecode(response.body);
      final bool isIgnored = responseData['data']['is_ignored'] ?? false;

      log(
        'ApiIgnoredDangerZonesService.isZoneIgnored: Zone $dangerZoneId is ${isIgnored ? 'ignored' : 'not ignored'}',
      );
      return isIgnored;
    } catch (e) {
      log('ApiIgnoredDangerZonesService.isZoneIgnored: Error: $e');
      return false;
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    log('ApiIgnoredDangerZonesService: Disposed');
  }
}
