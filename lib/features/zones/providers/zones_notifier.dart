import 'dart:async';
import 'dart:developer';
import 'package:alertcontacts/core/repositories/zones_repository.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/zone.dart';
import '../../../core/errors/auth_exceptions.dart';
import 'zones_state.dart';

class ZonesNotifier extends ChangeNotifier {
  final ZonesRepository _zonesRepository;
  ZonesState _state = const ZonesState();

  ZonesNotifier(this._zonesRepository) {
    // Initialiser le repository au démarrage
    _initializeRepository();
  }

  /// Initialiser le repository avec le token d'authentification
  Future<void> _initializeRepository() async {
    try {
      await _zonesRepository.initialize();
    } catch (e) {
      log('Erreur lors de l\'initialisation du ZonesRepository: $e');
    }
  }

  // Getters pour accéder à l'état
  ZonesState get state => _state;
  ZonesStatus get status => _state.status;
  List<Zone> get zones => _state.zones;
  List<Zone> get filteredZones => _state.filteredZones;
  List<Zone> get safeZones => _state.safeZones;
  List<Zone> get dangerZones => _state.dangerZones;
  String? get errorMessage => _state.errorMessage;

  // Getters utilitaires
  bool get isLoading => _state.status == ZonesStatus.loading;
  bool get isUpdating => _state.status == ZonesStatus.updating;
  bool get isDeleting => _state.status == ZonesStatus.deleting;
  bool get hasError => _state.status == ZonesStatus.error;
  bool get isEmpty => _state.zones.isEmpty;
  int get safeZonesCount => _state.safeZonesCount;
  int get dangerZonesCount => _state.dangerZonesCount;

  // Méthode privée pour mettre à jour l'état
  void _updateState(ZonesState newState) {
    _state = newState;
    notifyListeners();
  }

  // Méthode pour effacer les messages d'erreur
  void clearError() {
    _updateState(
      _state.copyWith(errorMessage: null, status: ZonesStatus.loaded),
    );
  }

  /// Charger toutes les zones de l'utilisateur
  Future<void> loadZones() async {
    if (_state.status == ZonesStatus.loading) return;

    _updateState(
      _state.copyWith(status: ZonesStatus.loading, errorMessage: null),
    );

    try {
      log('ZonesNotifier.loadZones: Chargement des zones');

      final zones = await _zonesRepository.getMyZones(forceRefresh: true);

      log('ZonesNotifier.loadZones: ${zones.length} zones chargées');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.loaded,
          zones: zones,
          errorMessage: null,
        ),
      );
    } catch (error) {
      log('ZonesNotifier.loadZones: Erreur: $error');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
    }
  }

  /// Rafraîchir les zones (force le rechargement depuis l'API)
  Future<void> refreshZones() async {
    try {
      log('ZonesNotifier.refreshZones: Rafraîchissement des zones (forceRefresh = true)');

      // Forcer le rechargement depuis l'API en contournant le cache
      final zones = await _zonesRepository.getMyZones(forceRefresh: true);

      log('ZonesNotifier.refreshZones: ${zones.length} zones rafraîchies');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.loaded,
          zones: zones,
          errorMessage: null,
        ),
      );
    } catch (error) {
      log('ZonesNotifier.refreshZones: Erreur: $error');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
    }
  }

  /// Mettre à jour une zone
  Future<bool> updateZone(Zone zone, Map<String, dynamic> data) async {
    _updateState(
      _state.copyWith(status: ZonesStatus.updating, errorMessage: null),
    );

    try {
      log('ZonesNotifier.updateZone: Mise à jour de la zone ${zone.id}');

      final updatedZone = await _zonesRepository.updateZone(zone, data);

      // Mettre à jour la zone dans la liste locale
      final updatedZones = _state.zones
          .map((z) => z.id == updatedZone.id ? updatedZone : z)
          .toList();

      log('ZonesNotifier.updateZone: Zone ${zone.id} mise à jour avec succès');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.loaded,
          zones: updatedZones,
          errorMessage: null,
        ),
      );

      return true;
    } catch (error) {
      log('ZonesNotifier.updateZone: Erreur: $error');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
      return false;
    }
  }

  /// Supprimer une zone
  Future<bool> deleteZone(Zone zone) async {
    _updateState(
      _state.copyWith(status: ZonesStatus.deleting, errorMessage: null),
    );

    try {
      log('ZonesNotifier.deleteZone: Suppression de la zone ${zone.id}');

      final success = await _zonesRepository.deleteZone(zone);
      if (!success) {
        throw Exception('Échec de la suppression de la zone');
      }

      // Supprimer la zone de la liste locale
      final updatedZones = _state.zones.where((z) => z.id != zone.id).toList();

      log('ZonesNotifier.deleteZone: Zone ${zone.id} supprimée avec succès');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.loaded,
          zones: updatedZones,
          errorMessage: null,
        ),
      );

      return true;
    } catch (error) {
      log('ZonesNotifier.deleteZone: Erreur: $error');
      _updateState(
        _state.copyWith(
          status: ZonesStatus.error,
          errorMessage: _getErrorMessage(error),
        ),
      );
      return false;
    }
  }

  /// Appliquer des filtres
  void applyFilters({
    String? searchQuery,
    ZoneType? typeFilter,
    DangerSeverity? severityFilter,
  }) {
    _updateState(
      _state.copyWith(
        searchQuery: searchQuery,
        typeFilter: typeFilter,
        severityFilter: severityFilter,
      ),
    );
  }

  /// Effacer tous les filtres
  void clearFilters() {
    _updateState(
      _state.copyWith(
        searchQuery: null,
        typeFilter: null,
        severityFilter: null,
      ),
    );
  }

  /// Rechercher des zones par nom
  void searchZones(String query) {
    _updateState(_state.copyWith(searchQuery: query));
  }

  /// Filtrer par type de zone
  void filterByType(ZoneType? type) {
    _updateState(_state.copyWith(typeFilter: type));
  }

  /// Filtrer par sévérité (pour les zones de danger)
  void filterBySeverity(DangerSeverity? severity) {
    _updateState(_state.copyWith(severityFilter: severity));
  }

  /// Obtenir une zone par son ID
  Zone? getZoneById(String id) {
    try {
      return _state.zones.firstWhere((zone) => zone.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Convertir les erreurs en messages utilisateur
  String _getErrorMessage(dynamic error) {
    if (error is InvalidCredentialsException) {
      return 'Session expirée. Veuillez vous reconnecter.';
    } else if (error is NetworkException) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    } else if (error is Exception) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    } else {
      return 'Erreur inconnue. Veuillez réessayer.';
    }
  }
}
