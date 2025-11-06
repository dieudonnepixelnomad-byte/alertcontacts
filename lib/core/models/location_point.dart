// lib/core/models/location_point.dart
import 'package:equatable/equatable.dart';

/// Modèle pour un point de localisation collecté
/// 
/// Utilisé pour UC-L2: Envoi des positions en batch au backend
/// Structure simple sans logique métier
class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime capturedAtDevice;
  final String source; // 'gps', 'network', 'passive', 'fused'
  final bool foreground;
  final int? batteryLevel;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.capturedAtDevice,
    required this.source,
    required this.foreground,
    this.batteryLevel,
  });

  /// Conversion vers JSON pour envoi au backend
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'captured_at_device': capturedAtDevice.toUtc().toIso8601String(),
      'source': source,
      'foreground': foreground,
      'battery': batteryLevel,
    };
  }

  /// Création depuis JSON (pour tests ou cache local)
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      capturedAtDevice: DateTime.parse(json['captured_at_device']),
      source: json['source'] ?? 'gps',
      foreground: json['foreground'] ?? true,
      batteryLevel: json['battery']?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        capturedAtDevice,
        source,
        foreground,
        batteryLevel,
      ];

  @override
  String toString() {
    return 'LocationPoint(lat: $latitude, lng: $longitude, accuracy: $accuracy, '
        'source: $source, foreground: $foreground, time: $capturedAtDevice)';
  }
}