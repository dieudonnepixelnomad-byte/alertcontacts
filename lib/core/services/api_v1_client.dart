import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../errors/auth_exceptions.dart';
import 'http_client.dart';

/// Levée quand le serveur refuse une action faute de quota — CDC V4.1 §10.4.
///
/// Le client n'a alors qu'à afficher le paywall : le décompte fait autorité
/// côté serveur, jamais côté app.
class QuotaExceededException implements Exception {
  const QuotaExceededException({
    required this.message,
    required this.used,
    required this.limit,
    this.reason,
  });

  final String message;
  final int used;
  final int limit;
  final String? reason;

  @override
  String toString() => message;
}

/// Client HTTP du socle API v1 — CDC V4.1 §8.
///
/// Mutualise ce que les services V4.0 recopiaient un par un : en-têtes,
/// jeton, gestion d'erreurs, enveloppe `{status, data}`.
///
/// Le `User-Agent` explicite n'est pas cosmétique : le WAF devant l'API
/// bloque l'agent Dart par défaut, et les requêtes repartent en 403 sans lui.
class ApiV1Client {
  ApiV1Client({String? baseUrl, AppHttpClient? client})
      : _baseUrl = baseUrl ?? ApiConfig.baseUrlV1,
        _client = client ?? AppHttpClient();

  final String _baseUrl;
  final AppHttpClient _client;
  String? _bearerToken;

  static const Duration _timeout = Duration(seconds: 15);

  void setBearerToken(String? token) => _bearerToken = token;

  bool get hasToken => _bearerToken != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'AlertContacts/1.0 (Mobile; Flutter)',
        if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers).timeout(_timeout);

    return _unwrap(response, 'GET $path');
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: json.encode(body ?? const {}),
        )
        .timeout(_timeout);

    return _unwrap(response, 'POST $path');
  }

  Future<dynamic> delete(String path) async {
    final response = await _client
        .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(_timeout);

    return _unwrap(response, 'DELETE $path');
  }

  /// Déballe l'enveloppe `{status: ok, data: ...}` et traduit les erreurs.
  dynamic _unwrap(http.Response response, String context) {
    final status = response.statusCode;

    if (status == 200 || status == 201) {
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    }

    log('ApiV1Client $context ← $status : ${response.body}');

    Map<String, dynamic> payload = const {};
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Corps non-JSON (page d'erreur du reverse proxy, par exemple)
    }

    final message = payload['message'] as String?;

    switch (status) {
      case 401:
        throw const InvalidCredentialsException();
      case 403:
        // §10.4 — quota épuisé : le client affiche le paywall
        if (payload['reason'] == 'avoidance_quota') {
          throw QuotaExceededException(
            message: message ?? 'Tu as utilisé tes contournements de ce mois.',
            used: (payload['used'] as num?)?.toInt() ?? 0,
            limit: (payload['limit'] as num?)?.toInt() ?? 0,
            reason: payload['reason'] as String?,
          );
        }
        throw Exception(message ?? 'Accès refusé');
      case 404:
        throw Exception(message ?? 'Ressource introuvable');
      case 422:
        throw Exception(message ?? 'Données invalides');
      case 429:
        throw Exception(message ?? 'Trop de requêtes. Réessaie dans un instant.');
      case 503:
        throw Exception(message ?? 'Service momentanément indisponible.');
      default:
        throw Exception(message ?? 'Erreur HTTP $status');
    }
  }
}
