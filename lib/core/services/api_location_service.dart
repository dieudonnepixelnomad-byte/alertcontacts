import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../errors/auth_exceptions.dart';

class ApiLocationService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiLocationService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
      };

  void setBearerToken(String? token) => _bearerToken = token;

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 401:
        throw const InvalidCredentialsException();
      default:
        throw Exception('Erreur HTTP ${response.statusCode}');
    }
  }

  Future<void> pauseLocation({int? durationMinutes}) async {
    try {
      final body = durationMinutes != null
          ? json.encode({'duration': durationMinutes})
          : json.encode({});
      final response = await _client.post(
        Uri.parse('$baseUrl/location/pause'),
        headers: _headers,
        body: body,
      );
      _handleResponse(response);
      log('ApiLocationService: location paused (${durationMinutes ?? "indefinite"} min)');
    } catch (e) {
      log('ApiLocationService.pauseLocation error: $e');
      rethrow;
    }
  }

  Future<void> resumeLocation() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/location/resume'),
        headers: _headers,
      );
      _handleResponse(response);
      log('ApiLocationService: location resumed');
    } catch (e) {
      log('ApiLocationService.resumeLocation error: $e');
      rethrow;
    }
  }
}
