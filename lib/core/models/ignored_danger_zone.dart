// lib/core/models/ignored_danger_zone.dart
import 'danger_zone.dart';

class IgnoredDangerZone {
  final String id;
  final int dangerZoneId;
  final DangerZone? dangerZone;
  final DateTime ignoredAt;
  final DateTime? expiresAt;
  final String? reason;
  final bool isActive;
  final bool isExpired;

  IgnoredDangerZone({
    required this.id,
    required this.dangerZoneId,
    this.dangerZone,
    required this.ignoredAt,
    this.expiresAt,
    this.reason,
    required this.isActive,
    required this.isExpired,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'danger_zone_id': dangerZoneId,
    'danger_zone': dangerZone?.toJson(),
    'ignored_at': ignoredAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'reason': reason,
    'is_active': isActive,
    'is_expired': isExpired,
  };

  factory IgnoredDangerZone.fromJson(Map<String, dynamic> json) {
    try {
      return IgnoredDangerZone(
        id: (json['id'] ?? '').toString(),
        dangerZoneId: json['danger_zone_id'] is int 
            ? json['danger_zone_id'] as int
            : int.tryParse(json['danger_zone_id']?.toString() ?? '0') ?? 0,
        dangerZone: json['danger_zone'] != null 
            ? DangerZone.fromJson(json['danger_zone'] as Map<String, dynamic>)
            : null,
        ignoredAt: json['ignored_at'] != null 
            ? DateTime.parse(json['ignored_at'].toString())
            : DateTime.now(),
        expiresAt: json['expires_at'] != null 
            ? DateTime.parse(json['expires_at'].toString()) 
            : null,
        reason: json['reason']?.toString(),
        isActive: json['is_active'] is bool 
            ? json['is_active'] as bool 
            : (json['is_active']?.toString().toLowerCase() == 'true'),
        isExpired: json['is_expired'] is bool 
            ? json['is_expired'] as bool 
            : (json['is_expired']?.toString().toLowerCase() == 'true'),
      );
    } catch (e) {
      throw FormatException('Erreur lors du parsing de IgnoredDangerZone: $e');
    }
  }

  IgnoredDangerZone copyWith({
    String? id,
    int? dangerZoneId,
    DangerZone? dangerZone,
    DateTime? ignoredAt,
    DateTime? expiresAt,
    String? reason,
    bool? isActive,
    bool? isExpired,
  }) => IgnoredDangerZone(
    id: id ?? this.id,
    dangerZoneId: dangerZoneId ?? this.dangerZoneId,
    dangerZone: dangerZone ?? this.dangerZone,
    ignoredAt: ignoredAt ?? this.ignoredAt,
    expiresAt: expiresAt ?? this.expiresAt,
    reason: reason ?? this.reason,
    isActive: isActive ?? this.isActive,
    isExpired: isExpired ?? this.isExpired,
  );

  /// Vérifier si la zone ignorée est encore valide
  bool get isStillValid {
    if (isExpired) return false;
    if (expiresAt == null) return isActive;
    return isActive && DateTime.now().isBefore(expiresAt!);
  }

  /// Obtenir le temps restant avant expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null || isExpired) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return null;
    return expiresAt!.difference(now);
  }

  /// Obtenir une description lisible du temps restant
  String get timeUntilExpirationText {
    final duration = timeUntilExpiration;
    if (duration == null) return 'Expiré';
    
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IgnoredDangerZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IgnoredDangerZone(id: $id, dangerZoneId: $dangerZoneId, isActive: $isActive)';
}