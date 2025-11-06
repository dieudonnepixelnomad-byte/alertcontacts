import 'package:equatable/equatable.dart';
import 'invitation.dart'; // Pour ShareLevel

enum RelationStatus { pending, accepted, refused }

class Contact extends Equatable {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const Contact({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl];
}

class ContactRelation extends Equatable {
  final String id;
  final Contact contact;
  final RelationStatus status;
  final ShareLevel shareLevel;
  final bool canSeeMe;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? refusedAt;

  const ContactRelation({
    required this.id,
    required this.contact,
    required this.status,
    required this.shareLevel,
    required this.canSeeMe,
    required this.createdAt,
    this.acceptedAt,
    this.refusedAt,
  });

  // Getters utiles
  bool get isActive => status == RelationStatus.accepted;
  bool get isPending => status == RelationStatus.pending;
  bool get isRefused => status == RelationStatus.refused;

  bool get isRealtimeSharing => 
      isActive && shareLevel == ShareLevel.realtime && canSeeMe;

  bool get isAlertOnlySharing => 
      isActive && shareLevel == ShareLevel.alertOnly && canSeeMe;

  bool get hasNoSharing => 
      !isActive || shareLevel == ShareLevel.none || !canSeeMe;

  factory ContactRelation.fromJson(Map<String, dynamic> json) {
    return ContactRelation(
      id: json['id'].toString(),
      contact: Contact.fromJson(json['contact'] as Map<String, dynamic>),
      status: _parseStatus(json['status'] as String),
      shareLevel: _parseShareLevel(json['share_level'] as String),
      canSeeMe: json['can_see_me'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at'] as String) 
          : null,
      refusedAt: json['refused_at'] != null 
          ? DateTime.parse(json['refused_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact.toJson(),
      'status': _statusToString(status),
      'share_level': _shareLevelToString(shareLevel),
      'can_see_me': canSeeMe,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'refused_at': refusedAt?.toIso8601String(),
    };
  }

  static RelationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return RelationStatus.pending;
      case 'accepted':
        return RelationStatus.accepted;
      case 'refused':
        return RelationStatus.refused;
      default:
        return RelationStatus.pending;
    }
  }

  static ShareLevel _parseShareLevel(String shareLevel) {
    switch (shareLevel) {
      case 'realtime':
        return ShareLevel.realtime;
      case 'alert_only':
        return ShareLevel.alertOnly;
      case 'none':
        return ShareLevel.none;
      default:
        return ShareLevel.none;
    }
  }

  static String _statusToString(RelationStatus status) {
    switch (status) {
      case RelationStatus.pending:
        return 'pending';
      case RelationStatus.accepted:
        return 'accepted';
      case RelationStatus.refused:
        return 'refused';
    }
  }

  static String _shareLevelToString(ShareLevel shareLevel) {
    switch (shareLevel) {
      case ShareLevel.realtime:
        return 'realtime';
      case ShareLevel.alertOnly:
        return 'alert_only';
      case ShareLevel.none:
        return 'none';
    }
  }

  ContactRelation copyWith({
    String? id,
    Contact? contact,
    RelationStatus? status,
    ShareLevel? shareLevel,
    bool? canSeeMe,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? refusedAt,
  }) {
    return ContactRelation(
      id: id ?? this.id,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      shareLevel: shareLevel ?? this.shareLevel,
      canSeeMe: canSeeMe ?? this.canSeeMe,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      refusedAt: refusedAt ?? this.refusedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contact,
        status,
        shareLevel,
        canSeeMe,
        createdAt,
        acceptedAt,
        refusedAt,
      ];
}

// Classe pour les statistiques des relations
class RelationStats extends Equatable {
  final int total;
  final int accepted;
  final int pending;
  final int refused;
  final int realtimeSharing;
  final int alertOnlySharing;

  const RelationStats({
    required this.total,
    required this.accepted,
    required this.pending,
    required this.refused,
    required this.realtimeSharing,
    required this.alertOnlySharing,
  });

  factory RelationStats.fromJson(Map<String, dynamic> json) {
    return RelationStats(
      total: json['total'] as int,
      accepted: json['accepted'] as int,
      pending: json['pending'] as int,
      refused: json['refused'] as int,
      realtimeSharing: json['realtime_sharing'] as int,
      alertOnlySharing: json['alert_only_sharing'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'accepted': accepted,
      'pending': pending,
      'refused': refused,
      'realtime_sharing': realtimeSharing,
      'alert_only_sharing': alertOnlySharing,
    };
  }

  @override
  List<Object?> get props => [
        total,
        accepted,
        pending,
        refused,
        realtimeSharing,
        alertOnlySharing,
      ];
}

// Extensions utiles
extension RelationStatusExtension on RelationStatus {
  String get displayName {
    switch (this) {
      case RelationStatus.pending:
        return 'En attente';
      case RelationStatus.accepted:
        return 'Accepté';
      case RelationStatus.refused:
        return 'Refusé';
    }
  }
}