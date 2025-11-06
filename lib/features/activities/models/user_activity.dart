import 'package:equatable/equatable.dart';

class UserActivity extends Equatable {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const UserActivity({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as int,
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        action,
        entityType,
        entityId,
        metadata,
        ipAddress,
        userAgent,
        createdAt,
      ];

  // Méthodes utilitaires pour obtenir des informations formatées
  String get actionDisplayName {
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

  String get entityTypeDisplayName {
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

  String? get locationName {
    return metadata?['name'] as String?;
  }

  double? get latitude {
    final lat = metadata?['latitude'];
    if (lat is num) return lat.toDouble();
    return null;
  }

  double? get longitude {
    final lng = metadata?['longitude'];
    if (lng is num) return lng.toDouble();
    return null;
  }

  String? get severity {
    return metadata?['severity'] as String?;
  }

  double? get distance {
    final dist = metadata?['distance'];
    if (dist is num) return dist.toDouble();
    return null;
  }

  int? get radius {
    final rad = metadata?['radius'];
    if (rad is num) return rad.toInt();
    return null;
  }

  String? get icon {
    return metadata?['icon'] as String?;
  }

  bool get isLocationActivity {
    return action.contains('zone') || action.contains('enter') || action.contains('exit');
  }

  bool get isAuthActivity {
    return ['login', 'logout', 'register'].contains(action);
  }

  bool get isDangerZoneActivity {
    return action.contains('danger_zone') || entityType == 'DangerZone';
  }

  bool get isSafeZoneActivity {
    return action.contains('safe_zone') || entityType == 'SafeZone';
  }
}