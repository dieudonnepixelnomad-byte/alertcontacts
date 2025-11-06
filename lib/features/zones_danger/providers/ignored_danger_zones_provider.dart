import 'package:flutter/foundation.dart';
import '../../../core/models/ignored_danger_zone.dart';
import '../../../core/repositories/ignored_danger_zone_repository.dart';
import '../../../core/providers/auth_aware_provider.dart';

class IgnoredDangerZonesProvider extends ChangeNotifier with AuthAwareProvider {
  final IgnoredDangerZoneRepository _repository;
  
  List<IgnoredDangerZone> _ignoredZones = [];
  bool _isLoading = false;
  String? _error;

  IgnoredDangerZonesProvider({
    required IgnoredDangerZoneRepository repository,
  }) : _repository = repository;

  // Getters
  List<IgnoredDangerZone> get ignoredZones => _ignoredZones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtres
  List<IgnoredDangerZone> get activeIgnoredZones => 
      _ignoredZones.where((zone) => zone.isStillValid).toList();

  List<IgnoredDangerZone> get expiredIgnoredZones => 
      _ignoredZones.where((zone) => zone.isExpired).toList();

  int get activeIgnoredZonesCount => activeIgnoredZones.length;

  @override
  void onAuthTokenChanged(String? token) {
    if (token != null) {
      _repository.initialize();
      loadIgnoredZones();
    } else {
      _clearData();
    }
  }

  /// Charger les zones ignorées
  Future<void> loadIgnoredZones() async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final zones = await _repository.getIgnoredZones();
      _ignoredZones = zones;
      
      debugPrint('IgnoredDangerZonesProvider: Loaded ${zones.length} ignored zones');
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des zones ignorées: $e');
      debugPrint('IgnoredDangerZonesProvider.loadIgnoredZones: Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ignorer une zone de danger
  Future<bool> ignoreDangerZone({
    required int dangerZoneId,
    required String reason,
    DateTime? expiresAt,
  }) async {
    try {
      _clearError();

      final ignoredZone = await _repository.ignoreDangerZone(
        dangerZoneId: dangerZoneId,
        reason: reason,
        expiresAt: expiresAt,
      );

      // Ajouter la nouvelle zone ignorée à la liste
      _ignoredZones.add(ignoredZone);
      notifyListeners();

      debugPrint('IgnoredDangerZonesProvider: Zone $dangerZoneId ignored successfully');
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ignorage de la zone: $e');
      debugPrint('IgnoredDangerZonesProvider.ignoreDangerZone: Error: $e');
      return false;
    }
  }

  /// Réactiver les alertes pour une zone
  Future<bool> reactivateDangerZone(int dangerZoneId) async {
    try {
      _clearError();

      await _repository.reactivateDangerZone(dangerZoneId);

      // Retirer la zone de la liste des zones ignorées
      _ignoredZones.removeWhere((zone) => zone.dangerZoneId == dangerZoneId);
      notifyListeners();

      debugPrint('IgnoredDangerZonesProvider: Zone $dangerZoneId reactivated successfully');
      return true;
    } catch (e) {
      _setError('Erreur lors de la réactivation: $e');
      debugPrint('IgnoredDangerZonesProvider.reactivateDangerZone: Error: $e');
      return false;
    }
  }

  /// Étendre la durée d'une zone ignorée
  Future<bool> extendIgnoredZone(int dangerZoneId) async {
    try {
      _clearError();

      final success = await _repository.extendIgnoredZone(dangerZoneId);

      if (success) {
        // Recharger les zones pour obtenir les nouvelles dates d'expiration
        await loadIgnoredZones();
        debugPrint('IgnoredDangerZonesProvider: Zone $dangerZoneId extended successfully');
      }

      return success;
    } catch (e) {
      _setError('Erreur lors de la prolongation: $e');
      debugPrint('IgnoredDangerZonesProvider.extendIgnoredZone: Error: $e');
      return false;
    }
  }

  /// Vérifier si une zone est ignorée
  Future<bool> isZoneIgnored(int dangerZoneId) async {
    try {
      return await _repository.isZoneIgnored(dangerZoneId);
    } catch (e) {
      debugPrint('IgnoredDangerZonesProvider.isZoneIgnored: Error: $e');
      return false;
    }
  }

  /// Vérifier si une zone est ignorée localement (sans appel API)
  bool isZoneIgnoredLocally(int dangerZoneId) {
    return _ignoredZones.any((zone) => 
        zone.dangerZoneId == dangerZoneId && zone.isStillValid);
  }

  /// Obtenir une zone ignorée par son ID de zone de danger
  IgnoredDangerZone? getIgnoredZone(int dangerZoneId) {
    try {
      return _ignoredZones.firstWhere((zone) => 
          zone.dangerZoneId == dangerZoneId && zone.isStillValid);
    } catch (e) {
      return null;
    }
  }

  /// Nettoyer les zones expirées localement
  void cleanupExpiredZones() {
    final initialCount = _ignoredZones.length;
    _ignoredZones.removeWhere((zone) => zone.isExpired);
    
    if (_ignoredZones.length != initialCount) {
      notifyListeners();
      debugPrint('IgnoredDangerZonesProvider: Cleaned up ${initialCount - _ignoredZones.length} expired zones');
    }
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadIgnoredZones();
  }

  // Méthodes privées pour la gestion de l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearData() {
    _ignoredZones.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearData();
    super.dispose();
  }
}