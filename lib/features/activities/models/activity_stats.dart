import 'package:equatable/equatable.dart';

class ActivityStats extends Equatable {
  final int periodDays;
  final int totalActivities;
  final Map<String, int> activitiesByAction;
  final Map<String, int> activitiesByEntity;
  final Map<String, int> activitiesByDay;

  const ActivityStats({
    required this.periodDays,
    required this.totalActivities,
    required this.activitiesByAction,
    required this.activitiesByEntity,
    required this.activitiesByDay,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      periodDays: json['period_days'] as int,
      totalActivities: json['total_activities'] as int,
      activitiesByAction: Map<String, int>.from(
        (json['activities_by_action'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as int)),
      ),
      activitiesByEntity: Map<String, int>.from(
        (json['activities_by_entity'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as int)),
      ),
      activitiesByDay: Map<String, int>.from(
        (json['activities_by_day'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as int)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_days': periodDays,
      'total_activities': totalActivities,
      'activities_by_action': activitiesByAction,
      'activities_by_entity': activitiesByEntity,
      'activities_by_day': activitiesByDay,
    };
  }

  @override
  List<Object?> get props => [
        periodDays,
        totalActivities,
        activitiesByAction,
        activitiesByEntity,
        activitiesByDay,
      ];

  // Méthodes utilitaires pour obtenir des informations formatées
  String get mostFrequentAction {
    if (activitiesByAction.isEmpty) return 'Aucune';
    
    final sortedActions = activitiesByAction.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return _getActionDisplayName(sortedActions.first.key);
  }

  String get mostFrequentEntity {
    if (activitiesByEntity.isEmpty) return 'Aucune';
    
    final sortedEntities = activitiesByEntity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return _getEntityDisplayName(sortedEntities.first.key);
  }

  double get averageActivitiesPerDay {
    if (periodDays == 0) return 0.0;
    return totalActivities / periodDays;
  }

  List<MapEntry<String, int>> get topActions {
    final sortedActions = activitiesByAction.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedActions.take(5).toList();
  }

  List<MapEntry<String, int>> get topEntities {
    final sortedEntities = activitiesByEntity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntities.take(5).toList();
  }

  List<MapEntry<DateTime, int>> get dailyActivities {
    return activitiesByDay.entries
        .map((entry) => MapEntry(DateTime.parse(entry.key), entry.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  String _getActionDisplayName(String action) {
    switch (action) {
      case 'login':
        return 'Connexion';
      case 'logout':
        return 'Déconnexion';
      case 'register':
        return 'Inscription';
      case 'create_danger_zone':
        return 'Création zone de danger';
      case 'delete_danger_zone':
        return 'Suppression zone de danger';
      case 'create_safe_zone':
        return 'Création zone de sécurité';
      case 'delete_safe_zone':
        return 'Suppression zone de sécurité';

      case 'exit_safe_zone':
        return 'Sortie zone de sécurité';
      default:
        return action;
    }
  }

  String _getEntityDisplayName(String entityType) {
    switch (entityType) {
      case 'User':
        return 'Utilisateur';
      case 'DangerZone':
        return 'Zone de danger';
      case 'SafeZone':
        return 'Zone de sécurité';
      default:
        return entityType;
    }
  }
}