import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/location_point.dart';
import 'batch_sender_service.dart';

class NativeLocationService {
  static const MethodChannel _methodChannel = MethodChannel('com.alertcontacts.alertcontacts/location');
  static const EventChannel _eventChannel = EventChannel('com.alertcontacts.alertcontacts/location_stream');

  static final NativeLocationService _instance = NativeLocationService._internal();
  factory NativeLocationService() => _instance;
  NativeLocationService._internal();

  final BatchSenderService _batchSender = BatchSenderService();

  bool _isInitialized = false;
  bool _isTracking = false;
  StreamSubscription<dynamic>? _locationSubscription;

  bool get isTracking => _isTracking;

  final StreamController<LocationPoint> _locationController = StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get locationStream => _locationController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _batchSender.initialize();
    _isInitialized = true;
    developer.log('NativeLocationService initialized', name: 'NativeLocationService');
  }

  Future<void> startTracking() async {
    if (!_isInitialized) throw StateError('Service not initialized');
    if (_isTracking) return;

    try {
      await _methodChannel.invokeMethod('startLocationService');
      _locationSubscription = _eventChannel.receiveBroadcastStream().listen(_onLocationData, onError: _onLocationError);
      _isTracking = true;
      developer.log('Location tracking started', name: 'NativeLocationService');
    } on PlatformException catch (e) {
      developer.log("Failed to start tracking: '${e.message}'.", name: 'NativeLocationService');
    }
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      await _methodChannel.invokeMethod('stopLocationService');
      await _locationSubscription?.cancel();
      _isTracking = false;
      developer.log('Location tracking stopped', name: 'NativeLocationService');
    } on PlatformException catch (e) {
      developer.log("Failed to stop tracking: '${e.message}'.", name: 'NativeLocationService');
    }
  }

  void _onLocationData(dynamic data) {
    try {
      final Map<String, dynamic> locationData = Map<String, dynamic>.from(data);
      final locationPoint = LocationPoint(
        latitude: (locationData['latitude'] as num).toDouble(),
        longitude: (locationData['longitude'] as num).toDouble(),
        accuracy: (locationData['accuracy'] as num?)?.toDouble() ?? 0.0,
        speed: (locationData['speed'] as num?)?.toDouble(),
        heading: (locationData['bearing'] as num?)?.toDouble(),
        capturedAtDevice: DateTime.fromMillisecondsSinceEpoch((locationData['captured_at_device'] as num).toInt()),
        foreground: locationData['isForeground'] as bool? ?? true,
        source: locationData['source'] as String? ?? 'fused',
        batteryLevel: locationData['batteryLevel'] as int?,
      );

      _locationController.add(locationPoint);
      _batchSender.addLocationPoint(locationPoint);
    } catch (e) {
      developer.log('Error processing location data: $e', name: 'NativeLocationService');
    }
  }

  void _onLocationError(dynamic error) {
    developer.log('Location stream error: $error', name: 'NativeLocationService');
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationController.close();
    _batchSender.dispose();
  }
}