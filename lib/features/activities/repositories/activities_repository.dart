import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_activities_service.dart';
import '../models/user_activity.dart';
import '../models/activities_response.dart';
import '../models/activity_stats.dart';

class ActivitiesRepository {
  final ApiActivitiesService _apiService;

  ActivitiesRepository(this._apiService);

  /// Récupère les activités de l'utilisateur avec pagination et filtres
  Future<ActivitiesResponse> getActivities({
    int page = 1,
    int perPage = 20,
    String? action,
    String? entityType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await _apiService.getActivities(
        page: page,
        perPage: perPage,
        action: action,
        entityType: entityType,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['success'] == true) {
          return ActivitiesResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['error']?['message'] ?? 'Erreur lors de la récupération des activités');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des activités: $e');
    }
  }

  /// Récupère les statistiques d'activités de l'utilisateur
  Future<ActivityStats> getActivityStats({int days = 30}) async {
    try {
      final response = await _apiService.getActivityStats(
        days: days,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['success'] == true) {
          return ActivityStats.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          throw Exception(jsonData['error']?['message'] ?? 'Erreur lors de la récupération des statistiques');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Récupère les activités récentes (dernières 24h)
  Future<List<UserActivity>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await getActivities(
        page: 1,
        perPage: limit,
        dateFrom: DateTime.now().subtract(const Duration(days: 1)),
      );

      return response.activities;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des activités récentes: $e');
    }
  }

  /// Récupère les activités par type d'action
  Future<List<UserActivity>> getActivitiesByAction(String action, {int limit = 50}) async {
    try {
      final response = await getActivities(
        page: 1,
        perPage: limit,
        action: action,
      );

      return response.activities;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des activités par action: $e');
    }
  }

  /// Récupère les activités de géolocalisation (sorties de zones)
  Future<List<UserActivity>> getLocationActivities({int limit = 50}) async {
    try {
      final allActivities = <UserActivity>[];

      // Récupérer les activités de sortie de zone de sécurité
      final safeExitResponse = await getActivities(
        page: 1,
        perPage: limit,
        action: 'exit_safe_zone',
      );
      allActivities.addAll(safeExitResponse.activities);

      // Trier par date décroissante
      allActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allActivities.take(limit).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des activités de géolocalisation: $e');
    }
  }
}