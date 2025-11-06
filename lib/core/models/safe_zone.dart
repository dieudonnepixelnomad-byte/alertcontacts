// lib/core/models/safe_zone.dart
class LatLng {
  final double lat;
  final double lng;
  
  const LatLng(this.lat, this.lng);

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
    (json['lat'] as num).toDouble(),
    (json['lng'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng && runtimeType == other.runtimeType && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'LatLng($lat, $lng)';
}

class SafeZone {
  final String id;
  final String name;
  final String iconKey; // 'home', 'school', ...
  final LatLng center;
  final double radiusMeters;
  final String? address;
  final List<String> memberIds; // proches affectés
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SafeZone({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.center,
    required this.radiusMeters,
    this.address,
    this.memberIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_key': iconKey,
    'center': center.toJson(),
    'radius_meters': radiusMeters,
    'address': address,
    'member_ids': memberIds,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory SafeZone.fromJson(Map<String, dynamic> json) => SafeZone(
    id: json['id'].toString(), // Convertir int ou String en String
    name: json['name'] as String,
    iconKey: json['icon'] as String? ?? json['icon_key'] as String? ?? 'home', // Gérer les deux noms de champs
    center: LatLng.fromJson(json['center'] as Map<String, dynamic>),
    radiusMeters: (json['radius_m'] as num?)?.toDouble() ?? (json['radius_meters'] as num?)?.toDouble() ?? 0.0, // Gérer les deux noms de champs
    address: json['address'] as String?,
    memberIds: List<String>.from(json['member_ids'] as List? ?? []),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
  );

  SafeZone copyWith({
    String? id,
    String? name,
    String? iconKey,
    LatLng? center,
    double? radiusMeters,
    String? address,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SafeZone(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    center: center ?? this.center,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    address: address ?? this.address,
    memberIds: memberIds ?? this.memberIds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeZone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SafeZone(id: $id, name: $name, iconKey: $iconKey)';
}
