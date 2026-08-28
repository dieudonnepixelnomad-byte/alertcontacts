import 'dart:convert';
import '../config/api_config.dart';
import '../models/gps_tracker.dart';
import 'http_client.dart';
import 'prefs_service.dart';

class GpsTrackerService {
  final AppHttpClient _client = AppHttpClient();
  final PrefsService _prefs = PrefsService();

  Future<Map<String, String>> _headers() async {
    final token = await _prefs.getBearerToken();
    return {'Accept': 'application/json', 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }
  Future<GpsTrackerList> list() async {
    final response = await _client.get(Uri.parse('${ApiConfig.baseUrl}/gps-trackers'), headers: await _headers());
    if (response.statusCode != 200) throw Exception('Impossible de charger les traceurs.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GpsTrackerList(
      trackers: (data['data'] as List<dynamic>)
          .map((e) => GpsTracker.fromJson(e as Map<String, dynamic>))
          .toList(),
      capabilities: TrackerCapabilities.fromJson(
        data['capabilities'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
  Future<void> create({required String name, String? provider, String? externalIdentifier}) async {
    final response = await _client.post(Uri.parse('${ApiConfig.baseUrl}/gps-trackers'), headers: await _headers(), body: jsonEncode({'name': name, if (provider?.isNotEmpty == true) 'provider': provider, if (externalIdentifier?.isNotEmpty == true) 'external_identifier': externalIdentifier}));
    if (response.statusCode == 403) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] == 'GPS_TRACKER_FREE_LIMIT_REACHED') {
        throw const GpsTrackerFreeLimitException();
      }
    }
    if (response.statusCode != 201) throw Exception('Impossible d’ajouter ce traceur.');
  }
}

class GpsTrackerFreeLimitException implements Exception {
  const GpsTrackerFreeLimitException();
}
