import 'package:equatable/equatable.dart';
import '../../../core/models/zone.dart';

enum ZonesStatus {
  initial,
  loading,
  loaded,
  updating,
  deleting,
  error,
}

class ZonesState extends Equatable {
  final ZonesStatus status;
  final List<Zone> zones;
  final String? searchQuery;
  final ZoneType? typeFilter;
  final DangerSeverity? severityFilter;
  final String? errorMessage;

  const ZonesState({
    this.status = ZonesStatus.initial,
    this.zones = const [],
    this.searchQuery,
    this.typeFilter,
    this.severityFilter,
    this.errorMessage,
  });

  ZonesState copyWith({
    ZonesStatus? status,
    List<Zone>? zones,
    String? searchQuery,
    ZoneType? typeFilter,
    DangerSeverity? severityFilter,
    String? errorMessage,
  }) => ZonesState(
    status: status ?? this.status,
    zones: zones ?? this.zones,
    searchQuery: searchQuery ?? this.searchQuery,
    typeFilter: typeFilter ?? this.typeFilter,
    severityFilter: severityFilter ?? this.severityFilter,
    errorMessage: errorMessage,
  );

  // Getters utilitaires
  List<Zone> get safeZones => zones.where((zone) => zone.type == ZoneType.safe).toList();
  List<Zone> get dangerZones => zones.where((zone) => zone.type == ZoneType.danger).toList();
  
  int get totalZones => zones.length;
  int get safeZonesCount => safeZones.length;
  int get dangerZonesCount => dangerZones.length;

  // Zones filtrées selon les critères
  List<Zone> get filteredZones {
    var filtered = zones;

    // Filtre par type
    if (typeFilter != null) {
      filtered = filtered.where((zone) => zone.type == typeFilter).toList();
    }

    // Filtre par sévérité (pour les zones de danger)
    if (severityFilter != null) {
      filtered = filtered.where((zone) => 
        zone.type == ZoneType.danger && zone.severity == severityFilter
      ).toList();
    }

    // Filtre par recherche textuelle
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((zone) => 
        zone.name.toLowerCase().contains(query) ||
        (zone.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return filtered;
  }

  @override
  List<Object?> get props => [
    status,
    zones,
    searchQuery,
    typeFilter,
    severityFilter,
    errorMessage,
  ];
}