import 'package:equatable/equatable.dart';

enum InvitationStatus { pending, accepted, refused, expired }

enum ShareLevel { realtime, alertOnly, none }

class Invitation extends Equatable {
  final String id;
  final String token;
  final String? pin;
  final InvitationStatus status;
  final ShareLevel defaultShareLevel;
  final List<String> suggestedZones;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final String inviterName;
  final String? message;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? refusedAt;
  final String? invitationUrl;

  const Invitation({
    required this.id,
    required this.token,
    this.pin,
    required this.status,
    required this.defaultShareLevel,
    required this.suggestedZones,
    required this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.inviterName,
    this.message,
    required this.createdAt,
    this.acceptedAt,
    this.refusedAt,
    this.invitationUrl,
  });

  // Getters utiles
  bool get isValid => 
      status == InvitationStatus.pending && 
      !isExpired && 
      canBeUsed;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get canBeUsed => usedCount < maxUses;

  int get remainingUses => maxUses - usedCount;

  bool get requiresPin => pin != null && pin!.isNotEmpty;

  // Factory pour créer depuis JSON complet
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      pin: json['pin']?.toString(),
      status: _parseStatus(json['status']?.toString() ?? 'pending'),
      defaultShareLevel: _parseShareLevel(json['default_share_level']?.toString() ?? 'none'),
      suggestedZones: List<String>.from(json['suggested_zones'] ?? []),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'].toString()) 
          : DateTime.now().add(const Duration(hours: 24)),
      maxUses: json['max_uses'] as int? ?? 1,
      usedCount: json['used_count'] as int? ?? 0,
      inviterName: json['inviter_name']?.toString() ?? 'Utilisateur inconnu',
      message: json['message']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at'].toString()) 
          : null,
      refusedAt: json['refused_at'] != null 
          ? DateTime.parse(json['refused_at'].toString()) 
          : null,
      invitationUrl: json['invitation_url']?.toString(),
    );
  }

  // Factory spécifique pour la réponse de création d'invitation
  factory Invitation.fromCreateResponse(Map<String, dynamic> json) {
    return Invitation(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      pin: json['pin']?.toString(),
      status: InvitationStatus.pending, // Toujours pending lors de la création
      defaultShareLevel: _parseShareLevel(json['default_share_level']?.toString() ?? 'none'),
      suggestedZones: List<String>.from(json['suggested_zones'] ?? []),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'].toString()) 
          : DateTime.now().add(const Duration(hours: 24)),
      maxUses: json['max_uses'] as int? ?? 1,
      usedCount: 0, // Toujours 0 lors de la création
      inviterName: 'Vous', // Valeur par défaut pour l'inviteur
      message: json['message']?.toString(),
      createdAt: DateTime.now(), // Utiliser l'heure actuelle
      acceptedAt: null,
      refusedAt: null,
      invitationUrl: json['invitation_url']?.toString(),
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'pin': pin,
      'status': _statusToString(status),
      'default_share_level': _shareLevelToString(defaultShareLevel),
      'suggested_zones': suggestedZones,
      'expires_at': expiresAt.toIso8601String(),
      'max_uses': maxUses,
      'used_count': usedCount,
      'inviter_name': inviterName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'refused_at': refusedAt?.toIso8601String(),
      'invitation_url': invitationUrl,
    };
  }

  // Méthodes de parsing
  static InvitationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'refused':
        return InvitationStatus.refused;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
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

  static String _statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return 'pending';
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.refused:
        return 'refused';
      case InvitationStatus.expired:
        return 'expired';
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

  // CopyWith pour immutabilité
  Invitation copyWith({
    String? id,
    String? token,
    String? pin,
    InvitationStatus? status,
    ShareLevel? defaultShareLevel,
    List<String>? suggestedZones,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    String? inviterName,
    String? message,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? refusedAt,
    String? invitationUrl,
  }) {
    return Invitation(
      id: id ?? this.id,
      token: token ?? this.token,
      pin: pin ?? this.pin,
      status: status ?? this.status,
      defaultShareLevel: defaultShareLevel ?? this.defaultShareLevel,
      suggestedZones: suggestedZones ?? this.suggestedZones,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      inviterName: inviterName ?? this.inviterName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      refusedAt: refusedAt ?? this.refusedAt,
      invitationUrl: invitationUrl ?? this.invitationUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        token,
        pin,
        status,
        defaultShareLevel,
        suggestedZones,
        expiresAt,
        maxUses,
        usedCount,
        inviterName,
        message,
        createdAt,
        acceptedAt,
        refusedAt,
        invitationUrl,
      ];
}

// Extensions utiles
extension ShareLevelExtension on ShareLevel {
  String get displayName {
    switch (this) {
      case ShareLevel.realtime:
        return 'Temps réel';
      case ShareLevel.alertOnly:
        return 'Alertes uniquement';
      case ShareLevel.none:
        return 'Aucun partage';
    }
  }

  String get description {
    switch (this) {
      case ShareLevel.realtime:
        return 'Partage votre position en temps réel';
      case ShareLevel.alertOnly:
        return 'Partage uniquement les alertes de sécurité';
      case ShareLevel.none:
        return 'Aucune donnée partagée';
    }
  }
}

extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'En attente';
      case InvitationStatus.accepted:
        return 'Acceptée';
      case InvitationStatus.refused:
        return 'Refusée';
      case InvitationStatus.expired:
        return 'Expirée';
    }
  }
}