import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/prefs_service.dart';

class ApiActivitiesService {
  final PrefsService _prefsService = PrefsService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _prefsService.getBearerToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Récupère les activités de l'utilisateur avec pagination et filtres
  Future<http.Response> getActivities({
    int page = 1,
    int perPage = 20,
    String? action,
    String? entityType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (action != null && action.isNotEmpty) {
      queryParams['action'] = action;
    }

    if (entityType != null && entityType.isNotEmpty) {
      queryParams['entity_type'] = entityType;
    }

    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }

    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/activities',
    ).replace(queryParameters: queryParams);

    final headers = await _getHeaders();

    return await http.get(uri, headers: headers);
  }

  /// Récupère les statistiques d'activités de l'utilisateur
  Future<http.Response> getActivityStats({int days = 30}) async {
    final queryParams = <String, String>{'days': days.toString()};

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/activities/stats',
    ).replace(queryParameters: queryParams);

    final headers = await _getHeaders();

    return await http.get(uri, headers: headers);
  }
}
