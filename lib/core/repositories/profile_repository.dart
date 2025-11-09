import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/prefs_service.dart';
import '../errors/api_exceptions.dart';

class ProfileRepository {
  final PrefsService _prefs;
  final http.Client _client;

  ProfileRepository({
    PrefsService? prefs,
    http.Client? client,
  }) : _prefs = prefs ?? PrefsService(),
       _client = client ?? http.Client();

  /// Headers pour les requêtes API
  Future<Map<String, String>> get _headers async {
    final bearerToken = await _prefs.getBearerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    };
  }

  /// Récupère le profil utilisateur
  Future<User> getProfile() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.baseUrl).replace(path: '/user/profile'),
        headers: await _headers,
      );

      final data = _handleResponse(response);
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  /// Met à jour le profil utilisateur
  Future<User> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (photoUrl != null) body['photo_url'] = photoUrl;

      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/user/profile'),
        headers: await _headers,
        body: jsonEncode(body),
      );

      final data = _handleResponse(response);
      final updatedUser = User.fromJson(data['user'] as Map<String, dynamic>);
      
      // Mettre à jour le cache local
      await _prefs.setUserProfile(updatedUser);
      
      return updatedUser;
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  /// Exporte les données utilisateur (RGPD)
  Future<void> exportUserData() async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/user/export-data'),
        headers: await _headers,
      );

      _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  /// Supprime le compte utilisateur (RGPD)
  Future<void> deleteAccount() async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/user/account'),
        headers: await _headers,
      );

      _handleResponse(response);
      
      // Nettoyer le cache local
      await _prefs.clearUserProfile();
      await _prefs.clearBearerToken();
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  /// Met à jour les consentements RGPD
  Future<void> updateConsents({
    bool? locationConsent,
    bool? notificationConsent,
    bool? analyticsConsent,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (locationConsent != null) body['location_consent'] = locationConsent;
      if (notificationConsent != null) body['notification_consent'] = notificationConsent;
      if (analyticsConsent != null) body['analytics_consent'] = analyticsConsent;

      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/user/consents'),
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

  /// Demande la limitation du traitement des données (RGPD)
  Future<void> requestDataProcessingLimitation() async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/user/limit-processing'),
        headers: await _headers,
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