import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';
import 'batch_sender_service.dart';
import 'gps_trace_recorder.dart';
import 'local_geofencing_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final BatchSenderService _batchSender = BatchSenderService();
  final LocalGeofencingService _localGeofencing = LocalGeofencingService();

  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isInvisible = false;
  bool _acceptNextRegardlessOfAccuracy = false;
  StreamSubscription<Position>? _positionSubscription;
  final Battery _battery = Battery();

  // 50m: seuil réaliste en milieu urbain
  static const double _maxAccuracy = 50.0;

  bool get isTracking => _isTracking;

  final StreamController<LocationPoint> _locationController =
      StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get locationStream => _locationController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _batchSender.initialize();
    await _localGeofencing.initialize();
    // V4.1 §4.6 — mémorise les derniers mètres parcourus pour qu'un
    // signalement en déplacement produise un corridor et non un disque.
    // Simple écoute du flux existant : aucun capteur supplémentaire.
    GpsTraceRecorder().start();
    _configureBackgroundFetch();
    _isInitialized = true;
    developer.log('LocationService initialized', name: 'LocationService');
  }

  void _configureBackgroundFetch() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );
  }

  Future<void> _onBackgroundFetch(String taskId) async {
    developer.log('BackgroundFetch fired: $taskId', name: 'LocationService');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      final point = _toLocationPoint(position, foreground: false);
      _batchSender.addLocationPoint(point);
      _localGeofencing.checkLocation(point);
      _publishToRtdb(point);
    } catch (e) {
      developer.log(
        'BackgroundFetch position error: $e',
        name: 'LocationService',
      );
    }
    BackgroundFetch.finish(taskId);
  }

  void _onBackgroundFetchTimeout(String taskId) {
    developer.log('BackgroundFetch timeout: $taskId', name: 'LocationService');
    BackgroundFetch.finish(taskId);
  }

  Future<void> startTracking() async {
    if (!_isInitialized) throw StateError('Service not initialized');
    if (_isTracking) return;

    final LocationSettings settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 10),
            forceLocationManager: true,
          )
        : AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            activityType: ActivityType.other,
            pauseLocationUpdatesAutomatically: false,
          );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_onPosition, onError: _onError);

    _isTracking = true;
    BackgroundFetch.start();
    developer.log('Location tracking started', name: 'LocationService');
  }

  /// One-shot position — used to center map. Tries last known first (instant),
  /// then falls back to a fresh fix. Uses forceLocationManager on Android to
  /// bypass FusedLocationProvider (blocked by aggressive battery optimization
  /// on some devices).
  Future<LocationPoint?> getCurrentPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 3));
      if (last != null) {
        developer.log(
          'getCurrentPosition: last known acc=${last.accuracy}m',
          name: 'LocationService',
        );
        return _toLocationPoint(last, foreground: true);
      }
    } catch (e) {
      developer.log('getLastKnownPosition error: $e', name: 'LocationService');
    }

    try {
      final LocationSettings settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.medium,
              forceLocationManager: true,
            )
          : const LocationSettings(accuracy: LocationAccuracy.medium);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(const Duration(seconds: 30));
      return _toLocationPoint(position, foreground: true);
    } catch (e) {
      developer.log('getCurrentPosition error: $e', name: 'LocationService');
      return null;
    }
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    BackgroundFetch.stop();
    developer.log('Location tracking stopped', name: 'LocationService');
  }

  void _onPosition(Position position) {
    if (!_acceptNextRegardlessOfAccuracy && position.accuracy > _maxAccuracy) {
      developer.log(
        'Ignored low accuracy point: ${position.accuracy}m',
        name: 'LocationService',
      );
      return;
    }
    _acceptNextRegardlessOfAccuracy = false;
    final point = _toLocationPoint(position, foreground: true);
    _locationController.add(point);
    _batchSender.addLocationPoint(point);
    _localGeofencing.checkLocation(point);
    _publishToRtdb(point);
  }

  /// Publie la position vers Firebase Realtime DB : /locations/{uid}
  Future<void> _publishToRtdb(LocationPoint point) async {
    if (_isInvisible) return;
    try {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}
      await FirebaseDatabase.instance.ref('locations/$uid').update({
        'lat': point.latitude,
        'lng': point.longitude,
        'accuracy': point.accuracy,
        if (point.heading != null) 'heading': point.heading,
        'updated_at': point.capturedAtDevice.millisecondsSinceEpoch,
        'is_invisible': false,
        if (batteryLevel != null) 'battery': batteryLevel,
      });
    } catch (e) {
      developer.log('RTDB publish error: $e', name: 'LocationService');
    }
  }

  /// Active/désactive le mode invisible — stoppe la publication RDB
  /// et écrit `is_invisible: true` pour que les proches voient la pause.
  Future<void> setInvisibleMode(bool invisible) async {
    _isInvisible = invisible;
    try {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseDatabase.instance.ref('locations/$uid').update({
        'is_invisible': invisible,
      });
    } catch (e) {
      developer.log('RTDB setInvisibleMode error: $e', name: 'LocationService');
    }
  }

  void _onError(dynamic error) {
    developer.log('Location stream error: $error', name: 'LocationService');
  }

  LocationPoint _toLocationPoint(
    Position position, {
    required bool foreground,
  }) {
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed < 0 ? null : position.speed,
      heading: position.heading < 0 ? null : position.heading,
      capturedAtDevice: position.timestamp,
      source: 'geolocator',
      foreground: foreground,
    );
  }

  void acceptNextPointRegardlessOfAccuracy() {
    _acceptNextRegardlessOfAccuracy = true;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
    _batchSender.dispose();
  }
}
