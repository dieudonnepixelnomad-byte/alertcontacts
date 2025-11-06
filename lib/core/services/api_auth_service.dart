import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../errors/auth_exceptions.dart';

class ApiAuthService {
  final String baseUrl;
  final http.Client _client;
  String? _bearerToken;

  ApiAuthService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Headers par défaut pour les requêtes API
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
  };

  /// Échanger le token Firebase contre une session Sanctum
  Future<User> exchangeFirebaseToken(String idToken, Map<String, dynamic> userData) async {
    try {
      log('ApiAuthService.exchangeFirebaseToken: Starting token exchange');
      log('ApiAuthService.exchangeFirebaseToken: baseUrl = $baseUrl');
      log('ApiAuthService.exchangeFirebaseToken: idToken length = ${idToken.length}');
      log('ApiAuthService.exchangeFirebaseToken: userData = $userData');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/firebase-login'),
        headers: _headers,
        body: jsonEncode({
          'idToken': idToken,
          'userData': userData,
        }),
      );

      log('ApiAuthService.exchangeFirebaseToken: Response status = ${response.statusCode}');
      log('ApiAuthService.exchangeFirebaseToken: Response body = ${response.body}');

      final data = _handleResponse(response);

      // Stocker le token Bearer pour les futures requêtes
      _bearerToken = data['token'] as String?;
      log('ApiAuthService.exchangeFirebaseToken: Bearer token stored');

      // Retourner le profil utilisateur
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      log('ApiAuthService.exchangeFirebaseToken: User created successfully: ${user.id}');
      return user;
    } on SocketException catch (e) {
      log('ApiAuthService.exchangeFirebaseToken: SocketException: $e');
      throw const NetworkException();
    } catch (e) {
      log('ApiAuthService.exchangeFirebaseToken: Exception: $e');
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Inscription avec email et mot de passe
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      log(
        'Inscription avec email et mot de passe',
        name: 'ApiAuthService.register',
      );
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      log(
        'Réponse de l\'inscription',
        name: 'ApiAuthService.register',
        level: 100,
      );

      final data = _handleResponse(response);

      // Stocker le token Bearer pour les futures requêtes
      _bearerToken = data['token'] as String?;

      log('Utilisateur créé', name: 'ApiAuthService.register', level: 100);

      // Retourner le profil utilisateur
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Connexion avec email et mot de passe
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = _handleResponse(response);

      // Stocker le token Bearer pour les futures requêtes
      _bearerToken = data['token'] as String?;

      // Retourner le profil utilisateur
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Obtenir le profil utilisateur actuel
  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      final data = _handleResponse(response);
      return User.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Déconnexion (révocation du token Sanctum)
  Future<void> logout() async {
    try {
      await _client.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);

      // Nettoyer le token local
      _bearerToken = null;
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      // On ignore les erreurs de logout côté serveur
      // mais on nettoie quand même le token local
      _bearerToken = null;
    }
  }

  /// Rafraîchir la session avec un nouveau token Firebase
  Future<User> refreshSession(String idToken, Map<String, dynamic> userData) async {
    return exchangeFirebaseToken(idToken, userData);
  }

  /// Rafraîchir le token JWT
  Future<User> refreshToken() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _headers,
      );

      final data = _handleResponse(response);

      // Stocker le nouveau token Bearer
      _bearerToken = data['token'] as String?;

      // Retourner le profil utilisateur mis à jour
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw UnknownAuthException(e.toString());
    }
  }

  /// Définir le token Bearer manuellement (pour la persistance)
  void setBearerToken(String? token) {
    _bearerToken = token;
  }

  /// Obtenir le token Bearer actuel
  String? get bearerToken => _bearerToken;

  /// Envoyer le token FCM au backend (route publique - sans authentification)
  Future<void> sendFcmToken(String fcmToken, String platform, String email, {String? oldFcmToken}) async {
    try {
      log('ApiAuthService.sendFcmToken: Sending FCM token to backend');
      
      final body = {
        'fcm_token': fcmToken,
        'platform': platform,
        'email': email,
      };
      
      if (oldFcmToken != null) {
        body['old_fcm_token'] = oldFcmToken;
      }
      
      final response = await _client.post(
        Uri.parse('$baseUrl/users/fcm_token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log('ApiAuthService.sendFcmToken: Response status = ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        log('ApiAuthService.sendFcmToken: FCM token sent successfully');
      } else {
        log('ApiAuthService.sendFcmToken: Failed to send FCM token: ${response.body}');
        throw Exception('Failed to send FCM token: ${response.statusCode}');
      }
    } on SocketException {
      log('ApiAuthService.sendFcmToken: Network error');
      throw const NetworkException();
    } catch (e) {
      log('ApiAuthService.sendFcmToken: Exception: $e');
      rethrow;
    }
  }

  /// Gérer la réponse HTTP et mapper les erreurs
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
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
      case 'INVALID_ID_TOKEN':
        return const InvalidIdTokenException();
      case 'USER_DISABLED':
        return const UserDisabledException();
      case 'SYNC_ERROR':
        return const SyncErrorException();
      case 'TOO_MANY_REQUESTS':
        return const TooManyRequestsException();
      default:
        return UnknownAuthException(message ?? 'Erreur API inconnue');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _client.close();
  }
}
