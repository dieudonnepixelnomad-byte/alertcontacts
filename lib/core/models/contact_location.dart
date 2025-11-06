// lib/core/models/contact_location.dart
import 'package:equatable/equatable.dart';

/// Modèle pour une position d'un proche récupérée depuis l'API
/// 
/// Utilisé pour afficher l'historique des positions d'un contact
class ContactLocation extends Equatable {
  final int id;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime capturedAtDevice;
  final DateTime createdAt;
  final String source; // 'gps', 'network', 'passive', 'fused'
  final bool foreground;
  final int? batteryLevel;

  const ContactLocation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.capturedAtDevice,
    required this.createdAt,
    required this.source,
    required this.foreground,
    this.batteryLevel,
  });

  /// Création depuis JSON (réponse API)
  factory ContactLocation.fromJson(Map<String, dynamic> json) {
    return ContactLocation(
      id: json['id'] as int,
      userId: json['user_id'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      capturedAtDevice: DateTime.parse(json['captured_at_device'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      source: json['source'] as String? ?? 'gps',
      foreground: json['foreground'] as bool? ?? true,
      batteryLevel: json['battery'] as int?,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'captured_at_device': capturedAtDevice.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'source': source,
      'foreground': foreground,
      'battery': batteryLevel,
    };
  }

  /// Obtenir la durée depuis la capture
  Duration get timeSinceCapture => DateTime.now().difference(capturedAtDevice);

  /// Obtenir un texte formaté de la durée
  String get timeAgoText {
    final duration = timeSinceCapture;
    if (duration.inMinutes < 1) {
      return 'À l\'instant';
    } else if (duration.inHours < 1) {
      return 'Il y a ${duration.inMinutes} min';
    } else if (duration.inDays < 1) {
      return 'Il y a ${duration.inHours}h';
    } else {
      return 'Il y a ${duration.inDays}j';
    }
  }

  /// Obtenir un texte formaté de la précision
  String get accuracyText {
    if (accuracy < 10) {
      return 'Très précis (${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 50) {
      return 'Précis (${accuracy.toStringAsFixed(0)}m)';
    } else if (accuracy < 100) {
      return 'Approximatif (${accuracy.toStringAsFixed(0)}m)';
    } else {
      return 'Imprécis (${accuracy.toStringAsFixed(0)}m)';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        capturedAtDevice,
        createdAt,
        source,
        foreground,
        batteryLevel,
      ];

  @override
  String toString() {
    return 'ContactLocation(id: $id, userId: $userId, lat: $latitude, lng: $longitude, '
        'accuracy: $accuracy, source: $source, time: $capturedAtDevice)';
  }
}