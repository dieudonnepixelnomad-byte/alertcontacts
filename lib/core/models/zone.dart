// lib/core/models/zone.dart
import 'package:equatable/equatable.dart';
import 'safe_zone.dart';

enum ZoneType { safe, danger }

enum DangerSeverity { low, medium, high, critical }

class Zone extends Equatable {
  final String id;
  final ZoneType type;
  final String name; // Pour les zones de sécurité, c'est 'name', pour les zones de danger c'est 'title'
  final String? description;
  final LatLng center;
  final double radiusMeters;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Propriétés spécifiques aux zones de sécurité
  final String? iconKey;
  final String? address;
  final List<String>? memberIds;

  // Propriétés spécifiques aux zones de danger
  final DangerSeverity? severity;
  final int? confirmations;
  final DateTime? lastReportAt;

  const Zone({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.center,
    required this.radiusMeters,
    required this.createdAt,
    required this.updatedAt,
    this.iconKey,
    this.address,
    this.memberIds,
    this.severity,
    this.confirmations,
    this.lastReportAt,
  });

  // Factory pour créer une Zone à partir d'une SafeZone
  factory Zone.fromSafeZone(SafeZone safeZone) {
    return Zone(
      id: safeZone.id,
      type: ZoneType.safe,
      name: safeZone.name,
      description: null, // SafeZone n'a pas de description
      center: safeZone.center,
      radiusMeters: safeZone.radiusMeters,
      createdAt: safeZone.createdAt ?? DateTime.now(),
      updatedAt: safeZone.updatedAt ?? DateTime.now(),
      iconKey: safeZone.iconKey,
      address: safeZone.address,
      memberIds: safeZone.memberIds,
    );
  }

  // Factory pour créer une Zone à partir des données JSON de l'API
  factory Zone.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'safe' ? ZoneType.safe : ZoneType.danger;
    
    return Zone(
      id: json['id'].toString(), // Convertir en String au cas où ce serait un int
      type: type,
      name: type == ZoneType.safe ? json['name'] : json['title'],
      description: json['description'],
      center: LatLng(
        json['center']['lat'].toDouble(),
        json['center']['lng'].toDouble(),
      ),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0, // Valeur par défaut si null
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Propriétés spécifiques aux zones de sécurité
      iconKey: json['icon_key'],
      address: json['address'],
      memberIds: json['member_ids']?.cast<String>(),
      // Propriétés spécifiques aux zones de danger
      severity: json['severity'] != null 
          ? DangerSeverity.values.firstWhere(
              (e) => e.name == json['severity'],
              orElse: () => DangerSeverity.medium,
            )
          : null,
      confirmations: json['confirmations'],
      lastReportAt: json['last_report_at'] != null 
          ? DateTime.parse(json['last_report_at'])
          : null,
    );
  }

  // Convertir en JSON pour l'API
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type.name,
      'center': {
        'lat': center.lat,
        'lng': center.lng,
      },
      'radius_meters': radiusMeters,
    };

    if (type == ZoneType.safe) {
      json['name'] = name;
      json['description'] = description;
      json['icon_key'] = iconKey;
      json['address'] = address;
      json['member_ids'] = memberIds;
    } else {
      json['title'] = name;
      json['description'] = description;
      json['severity'] = severity?.name;
    }

    return json;
  }

  // Méthodes utilitaires
  bool get isSafe => type == ZoneType.safe;
  bool get isDanger => type == ZoneType.danger;

  String get displayName => name;
  
  String get subtitle {
    if (type == ZoneType.safe) {
      final memberCount = memberIds?.length ?? 0;
      return '${radiusMeters.toStringAsFixed(0)} m • $memberCount proche(s)';
    } else {
      return '${radiusMeters.toStringAsFixed(0)} m • ${severity?.name ?? 'medium'} • ${confirmations ?? 0} confirmations';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        description,
        center,
        radiusMeters,
        createdAt,
        updatedAt,
        iconKey,
        address,
        memberIds,
        severity,
        confirmations,
        lastReportAt,
      ];
}