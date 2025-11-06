import 'package:flutter/foundation.dart';
import '../../activities/models/user_activity.dart';
import '../../activities/models/activity_stats.dart';
import '../../activities/models/activities_response.dart';
import '../../activities/repositories/activities_repository.dart';

class ActivitiesProvider extends ChangeNotifier {
  final ActivitiesRepository _repository;

  ActivitiesProvider(this._repository);

  // État des activités
  List<UserActivity> _activities = [];
  ActivityPagination? _pagination;
  ActivityStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Filtres
  String? _selectedAction;
  String? _selectedEntityType;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Getters
  List<UserActivity> get activities => _activities;
  ActivityPagination? get pagination => _pagination;
  ActivityStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get selectedAction => _selectedAction;
  String? get selectedEntityType => _selectedEntityType;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  bool get hasMore => _pagination?.hasMorePages ?? false;
  bool get isEmpty => _activities.isEmpty && !_isLoading;

  /// Charge les activités avec pagination
  Future<void> loadActivities({
    int page = 1,
    int perPage = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      _activities.clear();
      _pagination = null;
      _error = null;
    }

    if (page == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    
    notifyListeners();

    try {
      // Charger les activités sans restriction premium
      DateTime? adjustedDateFrom = _dateFrom;
      DateTime? adjustedDateTo = _dateTo;

      final response = await _repository.getActivities(
        page: page,
        perPage: perPage,
        action: _selectedAction,
        entityType: _selectedEntityType,
        dateFrom: adjustedDateFrom,
        dateTo: adjustedDateTo,
      );

      if (page == 1) {
        _activities = response.activities;
      } else {
        _activities.addAll(response.activities);
      }

      _pagination = response.pagination;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Erreur lors du chargement des activités: $e');
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Charge plus d'activités (pagination)
  Future<void> loadMoreActivities() async {
    if (!hasMore || _isLoadingMore) return;

    final nextPage = (_pagination?.currentPage ?? 0) + 1;
    await loadActivities(page: nextPage);
  }

  /// Charge les statistiques d'activités
  Future<void> loadStats({int days = 30}) async {
    try {
      // Charger les statistiques sans restriction premium
      _stats = await _repository.getActivityStats(days: days);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Erreur lors du chargement des statistiques: $e');
      }
      notifyListeners();
    }
  }

  /// Vérifie si l'utilisateur a accès à l'historique détaillé (toujours true maintenant)
  Future<bool> hasHistoryAccess() async {
    return true;
  }

  /// Charge les statistiques avec vérification premium
  Future<void> loadStatsWithPremiumCheck({int days = 30}) async {
    final hasAccess = await hasHistoryAccess();
    
    if (!hasAccess && days > 30) {
      // Afficher un message d'information pour les utilisateurs gratuits
      _error = 'Historique limité à 30 jours. Passez à Premium pour un accès illimité.';
      notifyListeners();
      days = 30;
    }
    
    await loadStats(days: days);
  }

  /// Applique un filtre par action
  void setActionFilter(String? action) {
    if (_selectedAction != action) {
      _selectedAction = action;
      _refreshActivities();
    }
  }

  /// Applique un filtre par type d'entité
  void setEntityTypeFilter(String? entityType) {
    if (_selectedEntityType != entityType) {
      _selectedEntityType = entityType;
      _refreshActivities();
    }
  }

  /// Applique un filtre par date de début
  void setDateFromFilter(DateTime? dateFrom) {
    if (_dateFrom != dateFrom) {
      _dateFrom = dateFrom;
      _refreshActivities();
    }
  }

  /// Applique un filtre par date de fin
  void setDateToFilter(DateTime? dateTo) {
    if (_dateTo != dateTo) {
      _dateTo = dateTo;
      _refreshActivities();
    }
  }

  /// Applique un filtre par période
  void setDateRangeFilter(DateTime? from, DateTime? to) {
    if (_dateFrom != from || _dateTo != to) {
      _dateFrom = from;
      _dateTo = to;
      _refreshActivities();
    }
  }

  /// Efface tous les filtres
  void clearFilters() {
    bool hasFilters = _selectedAction != null ||
        _selectedEntityType != null ||
        _dateFrom != null ||
        _dateTo != null;

    if (hasFilters) {
      _selectedAction = null;
      _selectedEntityType = null;
      _dateFrom = null;
      _dateTo = null;
      _refreshActivities();
    }
  }

  /// Rafraîchit les activités (recharge depuis le début)
  Future<void> refreshActivities() async {
    await loadActivities(refresh: true);
  }

  /// Méthode privée pour rafraîchir après changement de filtre
  void _refreshActivities() {
    loadActivities(refresh: true);
  }

  /// Charge les activités récentes (pour affichage rapide)
  Future<List<UserActivity>> getRecentActivities({int limit = 10}) async {
    try {
      return await _repository.getRecentActivities(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des activités récentes: $e');
      }
      return [];
    }
  }

  /// Charge les activités par action
  Future<List<UserActivity>> getActivitiesByAction(String action, {int limit = 20}) async {
    try {
      return await _repository.getActivitiesByAction(action, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des activités par action: $e');
      }
      return [];
    }
  }

  /// Charge les activités liées à la localisation
  Future<List<UserActivity>> getLocationActivities({int limit = 20}) async {
    try {
      return await _repository.getLocationActivities(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des activités de localisation: $e');
      }
      return [];
    }
  }

  /// Efface l'erreur
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Obtient les actions disponibles pour les filtres
  List<String> get availableActions {
    return [
      'login',
      'logout',
      'register',
      'create_danger_zone',
      'delete_danger_zone',
      'create_safe_zone',
      'delete_safe_zone',
      'enter_danger_zone',
      'enter_safe_zone',
      'send_invitation',
      'accept_invitation',
      'reject_invitation',
    ];
  }

  /// Obtient les types d'entités disponibles pour les filtres
  List<String> get availableEntityTypes {
    return [
      'user',
      'danger_zone',
      'safe_zone',
      'invitation',
      'relationship',
    ];
  }

  /// Obtient le nom d'affichage pour une action
  String getActionDisplayName(String action) {
    const actionNames = {
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'register': 'Inscription',
      'create_danger_zone': 'Création zone de danger',
      'delete_danger_zone': 'Suppression zone de danger',
      'create_safe_zone': 'Création zone de sécurité',
      'delete_safe_zone': 'Suppression zone de sécurité',

      'send_invitation': 'Envoi invitation',
      'accept_invitation': 'Acceptation invitation',
      'reject_invitation': 'Refus invitation',
    };
    return actionNames[action] ?? action;
  }

  /// Obtient le nom d'affichage pour un type d'entité
  String getEntityTypeDisplayName(String entityType) {
    const entityTypeNames = {
      'user': 'Utilisateur',
      'danger_zone': 'Zone de danger',
      'safe_zone': 'Zone de sécurité',
      'invitation': 'Invitation',
      'relationship': 'Relation',
    };
    return entityTypeNames[entityType] ?? entityType;
  }

  /// Obtient les limites actuelles de l'utilisateur (plus de limites maintenant)
  Future<Map<String, dynamic>> getUserLimits() async {
    return {};
  }

  /// Vérifie si l'utilisateur peut accéder aux filtres de date étendus (toujours true maintenant)
  Future<bool> canAccessExtendedDateFilters() async {
    return true;
  }

  /// Obtient la période maximale d'historique accessible
  Future<int> getMaxHistoryDays() async {
    final hasAccess = await hasHistoryAccess();
    return hasAccess ? 365 : 30; // 1 an pour premium, 30 jours pour gratuit
  }

  /// Vérifie si une période de date est accessible avec l'abonnement actuel
  Future<bool> isDateRangeAccessible(DateTime? from, DateTime? to) async {
    if (from == null) return true;
    
    final hasAccess = await hasHistoryAccess();
    if (hasAccess) return true;
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return !from.isBefore(thirtyDaysAgo);
  }

  /// Obtient un message d'information sur les limites d'historique
  Future<String?> getHistoryLimitMessage() async {
    final hasAccess = await hasHistoryAccess();
    if (hasAccess) return null;
    
    return 'Historique limité aux 30 derniers jours. Passez à Premium pour un accès illimité à votre historique de sécurité.';
  }
}