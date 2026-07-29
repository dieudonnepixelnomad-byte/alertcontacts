import 'package:equatable/equatable.dart';

enum AlertGravity { low, medium, high, critical }
enum AlertType { accident, fire, flood, suspect, theft, murder, other }
enum AlertVisibility { publicAlert, contactsOnly }

class CommunityAlert extends Equatable {
  final String id;
  final AlertType type;
  final AlertGravity gravity;
  final double lat;
  final double lng;
  final String? description;
  final bool isAnonymous;
  final AlertVisibility visibility;
  final int confirmations;
  final int denials;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? creatorName;

  const CommunityAlert({
    required this.id,
    required this.type,
    required this.gravity,
    required this.lat,
    required this.lng,
    required this.confirmations,
    required this.denials,
    required this.createdAt,
    required this.expiresAt,
    this.description,
    this.isAnonymous = false,
    this.visibility = AlertVisibility.publicAlert,
    this.creatorName,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  int get radiusMeters => switch (gravity) {
    AlertGravity.low      => 200,
    AlertGravity.medium   => 500,
    AlertGravity.high     => 1000,
    AlertGravity.critical => 2000,
  };

  String get gravityLabel => switch (gravity) {
    AlertGravity.low      => 'Faible',
    AlertGravity.medium   => 'Moyen',
    AlertGravity.high     => 'Élevé',
    AlertGravity.critical => 'Critique',
  };

  String get typeLabel => switch (type) {
    AlertType.accident => 'Accident',
    AlertType.fire     => 'Incendie',
    AlertType.flood    => 'Inondation',
    AlertType.suspect  => 'Personne suspecte',
    AlertType.theft    => 'Vol',
    AlertType.murder   => 'Meurtre',
    AlertType.other    => 'Autre',
  };

  factory CommunityAlert.fromJson(Map<String, dynamic> json) {
    return CommunityAlert(
      id: json['id'].toString(),
      type: _parseType(json['type'] as String? ?? 'other'),
      gravity: _parseGravity(json['gravity'] as String? ?? 'low'),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      description: json['description'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      visibility: json['visibility'] == 'contacts_only'
          ? AlertVisibility.contactsOnly
          : AlertVisibility.publicAlert,
      confirmations: json['confirmations'] as int? ?? 0,
      denials: json['denials'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      creatorName: json['creator_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': _typeToString(type),
    'gravity': _gravityToString(gravity),
    'lat': lat,
    'lng': lng,
    if (description != null) 'description': description,
    'is_anonymous': isAnonymous,
    'visibility': visibility == AlertVisibility.contactsOnly ? 'contacts_only' : 'public',
  };

  static AlertGravity _parseGravity(String s) => switch (s) {
    'medium'   => AlertGravity.medium,
    'high'     => AlertGravity.high,
    'critical' => AlertGravity.critical,
    _          => AlertGravity.low,
  };

  static AlertType _parseType(String s) => switch (s) {
    'accident' => AlertType.accident,
    'fire'     => AlertType.fire,
    'flood'    => AlertType.flood,
    'suspect'  => AlertType.suspect,
    'theft'    => AlertType.theft,
    'murder'   => AlertType.murder,
    _          => AlertType.other,
  };

  static String _gravityToString(AlertGravity g) => switch (g) {
    AlertGravity.low      => 'low',
    AlertGravity.medium   => 'medium',
    AlertGravity.high     => 'high',
    AlertGravity.critical => 'critical',
  };

  static String _typeToString(AlertType t) => switch (t) {
    AlertType.accident => 'accident',
    AlertType.fire     => 'fire',
    AlertType.flood    => 'flood',
    AlertType.suspect  => 'suspect',
    AlertType.theft    => 'theft',
    AlertType.murder   => 'murder',
    AlertType.other    => 'other',
  };

  CommunityAlert copyWith({int? confirmations, int? denials}) => CommunityAlert(
    id: id, type: type, gravity: gravity, lat: lat, lng: lng,
    description: description, isAnonymous: isAnonymous,
    visibility: visibility,
    confirmations: confirmations ?? this.confirmations,
    denials: denials ?? this.denials,
    createdAt: createdAt, expiresAt: expiresAt, creatorName: creatorName,
  );

  @override
  List<Object?> get props => [id, type, gravity, lat, lng, confirmations, denials, createdAt];
}
