import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get _baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://mobile.alertcontacts.net';

  static String get baseUrl => '$_baseUrl/api';

  /// Socle V4.1 — incidents communautaires & trajets (CDC §8).
  /// Les endpoints `/api/*` restent en service : la bascule se fait écran par écran.
  static String get baseUrlV1 => '$_baseUrl/api/v1';
  static String get baseUrlSync => '$_baseUrl/api';
  static String get baseUrlWithoutApi => _baseUrl;
  static String get baseUrlWithoutApiSync => _baseUrl;

  static Future<void> initialize() async {}

  static const int defaultTimeoutSeconds = 30;

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String getEndpointUrl(String endpoint) => '$baseUrl/$endpoint';

  static String getInvitationUrl(String token, {String? pin}) {
    var url = '$baseUrlWithoutApi/invitations/accept?t=$token';
    if (pin != null && pin.isNotEmpty) url += '&pin=$pin';
    return url;
  }
}
