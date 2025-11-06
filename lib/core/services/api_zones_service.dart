// lib/core/services/api_zones_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/zone.dart';
import '../errors/auth_exceptions.dart';

class ApiZonesService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiZonesService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Headers par défaut pour les requêtes API
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };

  /// Définir le token Bearer manuellement
  void setBearerToken(String? token) {
    _bearerToken = token;
  }

  /// Gestion des réponses HTTP
  dynamic _handleResponse(http.Response response) {
    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');

    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 401:
        throw const InvalidCredentialsException();
      case 403:
        throw Exception('Accès refusé');
      case 404:
        throw Exception('Ressource non trouvée');
      case 422:
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Données invalides');
      case 500:
        throw Exception('Erreur serveur interne');
      default:
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Récupérer toutes les zones de l'utilisateur
  Future<List<Zone>> getMyZones() async {
    log('ApiZoneService: getMyZones - tentative de récupération des zones');
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/my-zones'),
        headers: _headers,
      );

      log('ApiZoneService: getMyZones - réponse reçue: ${response.body}');

      final data = _handleResponse(response);

      log('ApiZoneService: getMyZones - données reçues: $data');

      final List<dynamic> zonesData = data['data']['zones'];
      log('ApiZoneService: getMyZones - zones reçues: $zonesData');

      return zonesData.map((zoneJson) => Zone.fromJson(zoneJson)).toList();
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      log('Erreur getMyZones: $e');
      rethrow;
    }
  }

  // Mettre à jour une zone de sécurité
  Future<Zone> updateSafeZone(String zoneId, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/safe-zones/$zoneId'),
        headers: _headers,
        body: json.encode(data),
      );

      final responseData = _handleResponse(response);
      return Zone.fromJson(responseData['data']);
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      log('Erreur updateSafeZone: $e');
      rethrow;
    }
  }

  // Mettre à jour une zone de danger
  Future<Zone> updateDangerZone(
    String zoneId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/danger-zones/$zoneId'),
        headers: _headers,
        body: json.encode(data),
      );

      final responseData = _handleResponse(response);
      return Zone.fromJson(responseData['data']);
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      log('Erreur updateDangerZone: $e');
      rethrow;
    }
  }

  // Supprimer une zone de sécurité
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/safe-zones/$zoneId'),
        headers: _headers,
      );

      _handleResponse(response);
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      log('Erreur deleteSafeZone: $e');
      rethrow;
    }
  }

  // Supprimer une zone de danger
  Future<void> deleteDangerZone(String zoneId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/danger-zones/$zoneId'),
        headers: _headers,
      );

      _handleResponse(response);
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      log('Erreur deleteDangerZone: $e');
      rethrow;
    }
  }

  // Méthode générique pour mettre à jour une zone
  Future<Zone> updateZone(Zone zone, Map<String, dynamic> data) async {
    if (zone.type == ZoneType.safe) {
      return updateSafeZone(zone.id, data);
    } else {
      return updateDangerZone(zone.id, data);
    }
  }

  // Méthode générique pour supprimer une zone
  Future<void> deleteZone(Zone zone) async {
    if (zone.type == ZoneType.safe) {
      await deleteSafeZone(zone.id);
    } else {
      await deleteDangerZone(zone.id);
    }
  }
}
