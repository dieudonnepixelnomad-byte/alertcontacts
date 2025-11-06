import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/prefs_service.dart';
import '../errors/api_exceptions.dart';

class UserSetupRepository {
  final PrefsService _prefs;
  final http.Client _client;

  UserSetupRepository({PrefsService? prefs, http.Client? client})
      : _prefs = prefs ?? PrefsService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> get _headers async {
    final bearerToken = await _prefs.getBearerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    };
  }

  /// Soumet les informations de setup utilisateur au backend
  Future<void> submitSetup(Map<String, dynamic> payload) async {
    try {
      // Envoi des données d'onboarding vers l'endpoint dédié côté backend
      final body = {
        'payload': payload,
      };
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/user/onboarding'),
        headers: await _headers,
        body: jsonEncode(body),
      );

      _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    switch (response.statusCode) {
      case 200:
      case 201:
        return data;
      case 400:
        throw BadRequestException(data['message'] as String? ?? 'Requête invalide');
      case 401:
        throw UnauthorizedException(data['message'] as String? ?? 'Non autorisé');
      case 403:
        throw ForbiddenException(data['message'] as String? ?? 'Accès interdit');
      case 404:
        throw NotFoundException(data['message'] as String? ?? 'Ressource non trouvée');
      case 422:
        throw ValidationException(
          data['message'] as String? ?? 'Erreur de validation',
          data['errors'] as Map<String, dynamic>?,
        );
      case 429:
        throw TooManyRequestsException(data['message'] as String? ?? 'Trop de requêtes');
      case 500:
        throw ServerException(data['message'] as String? ?? 'Erreur serveur');
      default:
        throw UnknownApiException(
          'Erreur HTTP ${response.statusCode}: ${data['message'] ?? 'Erreur inconnue'}',
        );
    }
  }

  void dispose() {
    _client.close();
  }
}