import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/community_alert.dart';
import '../errors/auth_exceptions.dart';

class ApiAlertsService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiAlertsService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
      };

  void setBearerToken(String? token) => _bearerToken = token;

  dynamic _handleResponse(http.Response response) {
    log('ApiAlertsService ${response.statusCode}: ${response.body}');
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 401:
        throw const InvalidCredentialsException();
      case 403:
        throw Exception('Accès refusé — abonnement requis');
      case 404:
        throw Exception('Ressource non trouvée');
      case 422:
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Données invalides');
      default:
        throw Exception('Erreur HTTP ${response.statusCode}');
    }
  }

  static const _timeout = Duration(seconds: 15);

  Future<List<CommunityAlert>> getNearbyAlerts({required double lat, required double lng}) async {
    try {
      final uri = Uri.parse('$baseUrl/alerts/nearby').replace(
        queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
      );
      log('ApiAlertsService.getNearbyAlerts → GET $uri | token: ${_bearerToken != null ? "SET" : "NULL"}');
      final response = await _client.get(uri, headers: _headers).timeout(_timeout);
      log('ApiAlertsService.getNearbyAlerts ← status ${response.statusCode} | body: ${response.body}');
      final data = _handleResponse(response) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];
      log('ApiAlertsService.getNearbyAlerts ← ${list.length} alertes');
      return list
          .map((e) => CommunityAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('ApiAlertsService.getNearbyAlerts error: $e');
      rethrow;
    }
  }

  Future<CommunityAlert> createAlert(Map<String, dynamic> payload) async {
    try {
      log('ApiAlertsService.createAlert → POST $baseUrl/alerts | token: ${_bearerToken != null ? "SET" : "NULL"} | payload: $payload');
      final response = await _client
          .post(Uri.parse('$baseUrl/alerts'), headers: _headers, body: json.encode(payload))
          .timeout(_timeout);
      log('ApiAlertsService.createAlert ← status ${response.statusCode} | body: ${response.body}');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return CommunityAlert.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      log('ApiAlertsService.createAlert error: $e');
      rethrow;
    }
  }

  Future<void> confirmAlert(String alertId) =>
      _voteAlert(alertId, 'confirm');

  Future<void> denyAlert(String alertId) =>
      _voteAlert(alertId, 'deny');

  Future<void> reportAlert(String alertId) =>
      _voteAlert(alertId, 'report');

  Future<void> _voteAlert(String alertId, String action) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/alerts/$alertId/$action'),
        headers: _headers,
      );
      _handleResponse(response);
    } catch (e) {
      log('ApiAlertsService.$action error: $e');
      rethrow;
    }
  }
}
