// lib/core/models/danger_zone.dart
import 'safe_zone.dart'; // Pour réutiliser LatLng
import '../enums/danger_type.dart';

enum DangerSeverity { low, med, high }

class DangerZone {
  final String id;
  final String title;
  final String? description;
  final LatLng center;
  final double radiusMeters;
  final DangerSeverity severity;
  final DangerType dangerType;
  final int confirmations;
  final DateTime lastReportAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reportedBy; // ID de l'utilisateur qui a signalé

  DangerZone({
    required this.id,
    required this.title,
    this.description,
    required this.center,
    required this.radiusMeters,
    required this.severity,
    required this.dangerType,
    required this.confirmations,
    required this.lastReportAt,
    this.createdAt,
    this.updatedAt,
    this.reportedBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'center': center.toJson(),
    'radius_meters': radiusMeters,
    'severity': severity.name,
    'danger_type': dangerType.value,
    'confirmations': confirmations,
    'last_report_at': lastReportAt.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'reported_by': reportedBy,
  };

  factory DangerZone.fromJson(Map<String, dynamic> json) => DangerZone(
    id: json['id'].toString(), // Convertir int ou String en String
    title: json['title']?.toString() ?? 'Zone de danger', // Gérer les valeurs nulles
    description: json['description']?.toString(),
    center: json['center'] != null 
        ? LatLng.fromJson(json['center'] as Map<String, dynamic>)
        : const LatLng(0.0, 0.0), // Valeur par défaut si center est null
    radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? (json['radius_m'] as num?)?.toDouble() ?? 100.0, // Gérer les deux noms de champs
    severity: DangerSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
      orElse: () => DangerSeverity.low,
    ),
    dangerType: DangerType.values.firstWhere(
      (e) => e.value == json['danger_type'],
      orElse: () => DangerType.autre,
    ),
    confirmations: json['confirmations'] as int? ?? 0,
    lastReportAt: DateTime.parse(json['last_report_at']?.toString() ?? json['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
    reportedBy: json['reported_by']?.toString(),
  );

  DangerZone copyWith({
    String? id,
    String? title,
    String? description,
    LatLng? center,
    double? radiusMeters,
    DangerSeverity? severity,
    DangerType? dangerType,
    int? confirmations,
    DateTime? lastReportAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reportedBy,
  }) => DangerZone(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    center: center ?? this.center,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    severity: severity ?? this.severity,
    dangerType: dangerType ?? this.dangerType,
    confirmations: confirmations ?? this.confirmations,
    lastReportAt: lastReportAt ?? this.lastReportAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    reportedBy: reportedBy ?? this.reportedBy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DangerZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DangerZone(id: $id, title: $title, severity: $severity)';
}