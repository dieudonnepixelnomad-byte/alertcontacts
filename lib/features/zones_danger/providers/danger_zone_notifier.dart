import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/models/danger_zone.dart';
import '../../../core/services/api_dangerzone_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/errors/danger_zone_exceptions.dart';
import '../../../core/repositories/dangerzone_repository.dart';

enum DangerZoneStatus {
  initial,
  loading,
  loaded,
  creating,
  created,
  confirming,
  confirmed,
  reporting,
  reported,
  deleting,
  deleted,
  error,
}

class DangerZoneState {
  final DangerZoneStatus status;
  final List<DangerZone> zones;
  final List<DangerZone> nearbyZones;
  final DangerZone? selectedZone;
  final DangerZone? proposedZone;
  final String? errorMessage;
  final bool hasNearbyZones;

  const DangerZoneState({
    this.status = DangerZoneStatus.initial,
    this.zones = const [],
    this.nearbyZones = const [],
    this.selectedZone,
    this.proposedZone,
    this.errorMessage,
    this.hasNearbyZones = false,
  });

  DangerZoneState copyWith({
    DangerZoneStatus? status,
    List<DangerZone>? zones,
    List<DangerZone>? nearbyZones,
    DangerZone? selectedZone,
    DangerZone? proposedZone,
    String? errorMessage,
    bool? hasNearbyZones,
    bool clearSelectedZone = false,
    bool clearProposedZone = false,
    bool clearError = false,
  }) {
    return DangerZoneState(
      status: status ?? this.status,
      zones: zones ?? this.zones,
      nearbyZones: nearbyZones ?? this.nearbyZones,
      selectedZone: clearSelectedZone
          ? null
          : (selectedZone ?? this.selectedZone),
      proposedZone: clearProposedZone
          ? null
          : (proposedZone ?? this.proposedZone),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasNearbyZones: hasNearbyZones ?? this.hasNearbyZones,
    );
  }
}

class DangerZoneNotifier extends ChangeNotifier {
  final ApiDangerZoneService _apiService;
  final DangerZoneRepository _repository;
  final PrefsService _prefs;

  DangerZoneState _state = const DangerZoneState();
  DangerZoneState get state => _state;

  DangerZoneNotifier({
    required ApiDangerZoneService apiService,
    required DangerZoneRepository repository,
    required PrefsService prefs,
  }) : _apiService = apiService,
       _repository = repository,
       _prefs = prefs;

  void _updateState(DangerZoneState newState) {
    _state = newState;
    // Différer notifyListeners() pour éviter setState() pendant build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Initialiser le notifier avec le token Bearer
  Future<void> initialize() async {
    final token = await _prefs.getBearerToken();
    if (token != null) {
      _apiService.setBearerToken(token);
      log('DangerZoneNotifier: Bearer token initialized');
    } else {
      log('DangerZoneNotifier: No bearer token found');
    }
  }

  /// S'assurer que l'utilisateur est authentifié
  Future<void> _ensureAuthenticated() async {
    final token = await _prefs.getBearerToken();
    if (token == null) {
      throw const InvalidCredentialsException();
    }
    _apiService.setBearerToken(token);
  }

  /// Charger les zones de danger dans une zone géographique
  Future<void> loadDangerZones({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.loading, clearError: true),
      );

      // S'assurer que l'utilisateur est authentifié
      await _ensureAuthenticated();

      final zones = await _apiService.getDangerZones(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );

      // Filtrer automatiquement les zones expirées
      final filteredZones = _apiService.filterExpiredZones(zones);

      _updateState(
        _state.copyWith(status: DangerZoneStatus.loaded, zones: filteredZones),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.loadDangerZones: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.loadDangerZones: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors du chargement des zones',
        ),
      );
    }
  }

  /// Créer une nouvelle zone de danger avec détection de doublons
  Future<void> createDangerZone(DangerZone dangerZone) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.creating, clearError: true),
      );

      // S'assurer que l'utilisateur est authentifié
      await _ensureAuthenticated();

      // Vérifier d'abord s'il y a des zones proches (détection de doublons)
      final nearbyZones = await _apiService.checkForDuplicates(
        lat: dangerZone.center.lat,
        lng: dangerZone.center.lng,
        radiusMeters: 100.0, // 100m de rayon pour détecter les doublons
      );

      if (nearbyZones.isNotEmpty) {
        // Il y a des zones proches, proposer de confirmer plutôt que créer
        _updateState(
          _state.copyWith(
            status: DangerZoneStatus.loaded,
            nearbyZones: nearbyZones,
            proposedZone: dangerZone,
            hasNearbyZones: true,
          ),
        );
        return;
      }

      // Aucune zone proche, créer la nouvelle zone
      final createdZone = await _apiService.createDangerZone(dangerZone);

      // Ajouter la nouvelle zone à la liste
      final updatedZones = List<DangerZone>.from(_state.zones)
        ..add(createdZone);

      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.created,
          zones: updatedZones,
          selectedZone: createdZone,
        ),
      );
    } on ValidationException catch (e) {
      log('DangerZoneNotifier.createDangerZone: ValidationException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Données invalides',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.createDangerZone: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.createDangerZone: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors de la création',
        ),
      );
    }
  }

  /// Confirmer une zone de danger existante
  Future<void> confirmDangerZone(String zoneId) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.confirming, clearError: true),
      );

      final updatedZone = await _apiService.confirmDangerZone(zoneId);

      // Mettre à jour la zone dans la liste
      final updatedZones = _state.zones.map((zone) {
        return zone.id == zoneId ? updatedZone : zone;
      }).toList();

      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.confirmed,
          zones: updatedZones,
          selectedZone: updatedZone,
        ),
      );
    } on AlreadyConfirmedException catch (e) {
      log(
        'DangerZoneNotifier.confirmDangerZone: AlreadyConfirmedException: $e',
      );
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Vous avez déjà confirmé cette zone',
        ),
      );
    } on ZoneNotFoundException catch (e) {
      log('DangerZoneNotifier.confirmDangerZone: ZoneNotFoundException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Zone introuvable',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.confirmDangerZone: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.confirmDangerZone: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors de la confirmation',
        ),
      );
    }
  }

  /// Signaler une zone de danger comme fake/obsolète
  Future<void> reportDangerZoneAbuse(String zoneId, String reason) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.reporting, clearError: true),
      );

      await _apiService.reportAbuse(zoneId, reason);

      _updateState(_state.copyWith(status: DangerZoneStatus.reported));
    } on ZoneNotFoundException catch (e) {
      log(
        'DangerZoneNotifier.reportDangerZoneAbuse: ZoneNotFoundException: $e',
      );
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Zone introuvable',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.reportDangerZoneAbuse: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.reportDangerZoneAbuse: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors du signalement',
        ),
      );
    }
  }

  /// Vérifier s'il y a des zones proches (détection de doublons)
  Future<void> checkNearbyZones({
    required double lat,
    required double lng,
    double radiusMeters = 100.0,
  }) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.loading, clearError: true),
      );

      final nearbyZones = await _apiService.checkForDuplicates(
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
      );

      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.loaded,
          nearbyZones: nearbyZones,
          hasNearbyZones: nearbyZones.isNotEmpty,
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.checkNearbyZones: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.checkNearbyZones: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors de la recherche',
        ),
      );
    }
  }

  /// Charger les détails d'une zone de danger spécifique
  Future<void> loadDangerZoneDetails(String zoneId) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.loading, clearError: true),
      );

      final zone = await _apiService.getDangerZoneById(zoneId);

      _updateState(
        _state.copyWith(status: DangerZoneStatus.loaded, selectedZone: zone),
      );
    } on ZoneNotFoundException catch (e) {
      log(
        'DangerZoneNotifier.loadDangerZoneDetails: ZoneNotFoundException: $e',
      );
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Zone introuvable',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.loadDangerZoneDetails: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.loadDangerZoneDetails: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors du chargement',
        ),
      );
    }
  }

  /// Supprimer une zone de danger
  Future<void> deleteDangerZone(String zoneId) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.deleting, clearError: true),
      );

      await _apiService.deleteDangerZone(zoneId);

      // Retirer la zone de la liste
      final updatedZones = _state.zones
          .where((zone) => zone.id != zoneId)
          .toList();

      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.deleted,
          zones: updatedZones,
          clearSelectedZone: true,
        ),
      );
    } on ZoneNotFoundException catch (e) {
      log('DangerZoneNotifier.deleteDangerZone: ZoneNotFoundException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Zone introuvable',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.deleteDangerZone: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.deleteDangerZone: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors de la suppression',
        ),
      );
    }
  }

  /// Rafraîchir les zones de danger (force le rechargement depuis l'API)
  Future<void> refreshDangerZones({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    // Recharger les zones sans afficher l'état de chargement
    try {
      log('DangerZoneNotifier.refreshDangerZones: Rafraîchissement des zones (forceRefresh = true)');
      
      // Forcer le rechargement depuis l'API en contournant le cache
      final zones = await _repository.getDangerZones(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        forceRefresh: true,
      );

      _updateState(
        _state.copyWith(status: DangerZoneStatus.loaded, zones: zones),
      );
    } catch (e) {
      log('DangerZoneNotifier.refreshDangerZones: Exception: $e');
      // En cas d'erreur lors du refresh, on garde l'état actuel
    }
  }

  /// Forcer la création d'une zone même s'il y a des zones proches
  Future<void> forceCreateDangerZone(DangerZone zone) async {
    try {
      _updateState(
        _state.copyWith(status: DangerZoneStatus.creating, clearError: true),
      );

      final createdZone = await _apiService.createDangerZone(zone);

      // Ajouter la nouvelle zone à la liste
      final updatedZones = List<DangerZone>.from(_state.zones)
        ..add(createdZone);

      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.created,
          zones: updatedZones,
          selectedZone: createdZone,
          nearbyZones: [], // Vider les zones proches
          hasNearbyZones: false,
          clearProposedZone: true,
        ),
      );
    } on ValidationException catch (e) {
      log('DangerZoneNotifier.forceCreateDangerZone: ValidationException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Données invalides',
        ),
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.forceCreateDangerZone: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.forceCreateDangerZone: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors de la création',
        ),
      );
    }
  }

  /// Effacer l'erreur
  void clearError() {
    _updateState(_state.copyWith(clearError: true));
  }

  /// Effacer les zones proches
  void clearNearbyZones() {
    _updateState(
      _state.copyWith(
        nearbyZones: [],
        hasNearbyZones: false,
        clearProposedZone: true,
      ),
    );
  }

  /// Sélectionner une zone
  void selectZone(DangerZone? zone) {
    _updateState(
      _state.copyWith(selectedZone: zone, clearSelectedZone: zone == null),
    );
  }

  /// Filtrer les zones par gravité
  List<DangerZone> getZonesBySeverity(String severity) {
    return _state.zones.where((zone) => zone.severity == severity).toList();
  }

  /// Calculer la distance entre deux points géographiques en mètres
  /// Utilise la formule de Haversine
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres
    
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLng = (lng2 - lng1) * (math.pi / 180);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Obtenir les zones dans un rayon donné
  List<DangerZone> getZonesInRadius(double lat, double lng, double radiusKm) {
    return _state.zones.where((zone) {
      final distance = _calculateDistance(
        lat,
        lng,
        zone.center.lat,
        zone.center.lng,
      );
      return distance <= (radiusKm * 1000); // Convertir km en mètres
    }).toList();
  }

  /// Nettoyer les zones expirées (plus de 30 jours)
  Future<void> cleanupExpiredZones() async {
    try {
      log('DangerZoneNotifier.cleanupExpiredZones: Starting cleanup');

      _updateState(
        _state.copyWith(status: DangerZoneStatus.loading, clearError: true),
      );

      final deletedCount = await _apiService.cleanupExpiredZones();

      // Recharger les zones après le nettoyage
      await loadDangerZones();

      log(
        'DangerZoneNotifier.cleanupExpiredZones: Cleaned up $deletedCount expired zones',
      );
    } on AuthException catch (e) {
      log('DangerZoneNotifier.cleanupExpiredZones: AuthException: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur d\'authentification',
        ),
      );
    } catch (e) {
      log('DangerZoneNotifier.cleanupExpiredZones: Exception: $e');
      _updateState(
        _state.copyWith(
          status: DangerZoneStatus.error,
          errorMessage: 'Erreur lors du nettoyage',
        ),
      );
    }
  }

  /// Vérifier si une zone est expirée
  bool isZoneExpired(DangerZone zone) {
    return _apiService.isZoneExpired(zone);
  }

  /// Filtrer automatiquement les zones expirées lors du chargement
  void _filterExpiredZones() {
    final filteredZones = _apiService.filterExpiredZones(_state.zones);
    if (filteredZones.length != _state.zones.length) {
      log(
        'DangerZoneNotifier._filterExpiredZones: Filtered ${_state.zones.length - filteredZones.length} expired zones',
      );
      _updateState(_state.copyWith(zones: filteredZones));
    }
  }

  /// Programmer un nettoyage automatique périodique
  void schedulePeriodicCleanup() {
    // Nettoyer les zones expirées toutes les 24 heures
    Timer.periodic(const Duration(hours: 24), (timer) {
      cleanupExpiredZones();
    });
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
