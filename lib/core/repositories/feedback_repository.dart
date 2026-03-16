// lib/core/repositories/feedback_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';
import '../services/prefs_service.dart';
import '../errors/api_exceptions.dart';

class FeedbackRepository {
  final http.Client _client;
  final PrefsService _prefs;

  FeedbackRepository({
    http.Client? client,
    required PrefsService prefs,
  })  : _client = client ?? http.Client(),
        _prefs = prefs;

  /// Headers pour les requêtes API
  Future<Map<String, String>> get _headers async {
    final token = await _prefs.getBearerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Soumet un feedback
  Future<void> submitFeedback({
    required String category,
    required String subject,
    required String message,
    String? appVersion,
    String? osVersion,
  }) async {
    try {
      final body = {
        'type': category,
        'subject': subject,
        'message': message,
        'app_version': appVersion,
        'device_info': osVersion,
      };

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/feedback'),
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

  /// Gère la réponse HTTP et lance les exceptions appropriées
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

  /// Nettoie les ressources
  void dispose() {
    _client.close();
  }
}