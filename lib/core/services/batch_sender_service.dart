// lib/core/services/batch_sender_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alertcontacts/core/providers/auth_aware_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_point.dart';
import 'prefs_service.dart';
import '../config/api_config.dart';

/// UC-L2: Envoi des positions en batch au backend
/// UC-R1: Résilience offline côté mobile
///
/// Responsabilités :
/// - Accumuler les points en batch
/// - Envoyer au backend via API REST
/// - Gérer le buffer offline avec retry
/// - Idempotency pour éviter les doublons
class BatchSenderService extends ChangeNotifier with AuthAwareProvider {
  static final BatchSenderService _instance = BatchSenderService._internal();
  factory BatchSenderService() => _instance;
  BatchSenderService._internal();

  // Configuration
  static const int _maxBatchSize = 50; // UC-L2: Taille batch ≤ 50 points
  static const int _maxBufferSize = 1000; // UC-R1: Buffer max offline
  static const Duration _batchInterval = Duration(seconds: 60); // Timer 60s
  static const Duration _retryDelay = Duration(seconds: 30);
  static const String _bufferKey = 'location_points_buffer';
  static const String _apiEndpoint = '/locations/batch';
  static String get _baseUrl => ApiConfig.baseUrlSync;

  // État interne
  final List<LocationPoint> _currentBatch = [];
  final List<LocationPoint> _offlineBuffer = [];
  Timer? _batchTimer;
  bool _isSending = false;
  bool _isInitialized = false;

  // Services
  final PrefsService _prefs = PrefsService();

  /// Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📍 BatchSenderService: Initializing...');

      // Charger le token d'authentification
      await initializeAuth();

      // Charger le buffer offline depuis le stockage
      await _loadOfflineBuffer();

      // Démarrer le timer de batch
      _startBatchTimer();

      _isInitialized = true;
      debugPrint('📍 BatchSenderService: Initialized successfully');

      // Tenter d'envoyer le buffer offline si présent
      if (_offlineBuffer.isNotEmpty) {
        debugPrint(
          '📍 BatchSenderService: Found ${_offlineBuffer.length} offline points, attempting to send...',
        );
        _sendOfflineBuffer();
      }
    } catch (e) {
      debugPrint('📍 BatchSenderService: Initialization failed: $e');
      rethrow;
    }
  }

  @override
  void onAuthTokenChanged(String? token) {
    if (kDebugMode) {
      debugPrint('📍 [BatchSenderService] Auth token updated.');
    }
    updateAuthToken(token);
  }

  /// UC-L2: Ajouter un point au batch courant
  void addLocationPoint(LocationPoint point) {
    if (!_isInitialized) {
      debugPrint('📍 BatchSenderService: Not initialized, buffering point offline');
      _addToOfflineBuffer(point);
      return;
    }

    _currentBatch.add(point);
    debugPrint(
      '📍 BatchSenderService: Added point to batch (${_currentBatch.length}/$_maxBatchSize)',
    );

    // Envoyer immédiatement si batch plein
    if (_currentBatch.length >= _maxBatchSize) {
      _sendCurrentBatch();
    }
  }

  /// Démarrer le timer de batch
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_currentBatch.isNotEmpty && !_isSending) {
        debugPrint(
          '📍 BatchSenderService: Timer triggered, sending batch of ${_currentBatch.length} points',
        );
        _sendCurrentBatch();
      }
    });
  }

  /// UC-L2: Envoyer le batch courant
  Future<void> _sendCurrentBatch() async {
    if (_currentBatch.isEmpty || _isSending) return;

    final batchToSend = List<LocationPoint>.from(_currentBatch);
    _currentBatch.clear();

    await _sendBatch(batchToSend);
  }

  /// Envoyer un batch de points
  Future<void> _sendBatch(List<LocationPoint> points) async {
    if (points.isEmpty) return;

    _isSending = true;

    try {
      debugPrint('📍 BatchSenderService: Sending batch of ${points.length} points...');

      // Vérifier la connectivité
      if (!await _hasNetworkConnection()) {
        debugPrint('📍 BatchSenderService: No network, adding to offline buffer');
        _addBatchToOfflineBuffer(points);
        return;
      }

      // Préparer le payload
      final payload = {
        'locations': points.map((p) => p.toJson()).toList(),
        'device_info': await _getDeviceInfo(),
        'batch_id': _generateBatchId(points),
      };

      // Envoyer via HTTP
      final response = await _sendHttpRequest(payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final accepted = responseData['accepted'] ?? points.length;
        debugPrint(
          '📍 BatchSenderService: Batch sent successfully, $accepted points accepted',
        );
      } else if (response.statusCode == 401) {
        // UC-L2: A2. 401 → stoppe envoi, notifie l'app de réauthentifier
        debugPrint(
          '📍 BatchSenderService: Authentication failed, stopping batch sending',
        );
        _addBatchToOfflineBuffer(points);
        // TODO: Notifier l'app pour réauthentification
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('📍 BatchSenderService: Failed to send batch: $e');
      // UC-L2: A1/A3. Offline/Timeout → buffer + retry
      _addBatchToOfflineBuffer(points);
      _scheduleRetry();
    } finally {
      _isSending = false;
    }
  }

  /// UC-R1: Envoyer le buffer offline
  Future<void> _sendOfflineBuffer() async {
    if (_offlineBuffer.isEmpty || _isSending) return;

    // Envoyer par chunks pour respecter la taille max de batch
    while (_offlineBuffer.isNotEmpty) {
      final chunkSize = _offlineBuffer.length > _maxBatchSize
          ? _maxBatchSize
          : _offlineBuffer.length;
      final chunk = _offlineBuffer.take(chunkSize).toList();

      await _sendBatch(chunk);

      // Retirer les points envoyés du buffer
      _offlineBuffer.removeRange(0, chunkSize);
      await _saveOfflineBuffer();

      // Petite pause entre les chunks
      if (_offlineBuffer.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Ajouter un point au buffer offline
  void _addToOfflineBuffer(LocationPoint point) {
    if (_offlineBuffer.length >= _maxBufferSize) {
      // FIFO: supprimer le plus ancien
      _offlineBuffer.removeAt(0);
    }
    _offlineBuffer.add(point);
    _saveOfflineBuffer();
  }

  /// Ajouter un batch au buffer offline
  void _addBatchToOfflineBuffer(List<LocationPoint> points) {
    for (final point in points) {
      _addToOfflineBuffer(point);
    }
  }

  /// UC-R1: Charger le buffer offline depuis le stockage
  Future<void> _loadOfflineBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = prefs.getString(_bufferKey);

      if (bufferJson != null) {
        final bufferData = json.decode(bufferJson) as List;
        _offlineBuffer.clear();
        
        // Filtrer les points avec des valeurs source valides
        const validSources = {'gps', 'network', 'passive', 'fused'};
        final validPoints = bufferData
            .map((item) => LocationPoint.fromJson(item))
            .where((point) => validSources.contains(point.source))
            .toList();
            
        _offlineBuffer.addAll(validPoints);
        
        final filteredCount = bufferData.length - validPoints.length;
        if (filteredCount > 0) {
          debugPrint('📍 BatchSenderService: Filtered out $filteredCount points with invalid source values');
        }
        
        debugPrint(
          '📍 BatchSenderService: Loaded ${_offlineBuffer.length} valid points from offline buffer',
        );
      }
    } catch (e) {
      debugPrint('📍 BatchSenderService: Failed to load offline buffer: $e');
    }
  }

  /// Sauvegarder le buffer offline
  Future<void> _saveOfflineBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = json.encode(
        _offlineBuffer.map((point) => point.toJson()).toList(),
      );
      await prefs.setString(_bufferKey, bufferJson);
    } catch (e) {
      debugPrint('📍 BatchSenderService: Failed to save offline buffer: $e');
    }
  }

  /// Vérifier la connectivité réseau
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Envoyer la requête HTTP
  Future<http.Response> _sendHttpRequest(Map<String, dynamic> payload) async {
    final url = Uri.parse('$_baseUrl$_apiEndpoint');

    // Préparer les headers avec authentification
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (currentToken != null) {
      headers['Authorization'] = 'Bearer $currentToken';
    }

    return await http
        .post(
          url,
          headers: headers,
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Générer un ID de batch pour l'idempotency
  String _generateBatchId(List<LocationPoint> points) {
    if (points.isEmpty) return '';

    final firstPoint = points.first;
    final lastPoint = points.last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'batch_${firstPoint.capturedAtDevice.millisecondsSinceEpoch}_'
        '${lastPoint.capturedAtDevice.millisecondsSinceEpoch}_'
        '${points.length}_$timestamp';
  }

  /// Obtenir les informations du device
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // TODO: Implémenter la collecte d'infos device
    return {
      'platform': Platform.operatingSystem,
      'app_version': '1.0.0', // Placeholder
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Programmer un retry avec backoff exponentiel
  void _scheduleRetry() {
    Timer(_retryDelay, () {
      if (_offlineBuffer.isNotEmpty) {
        debugPrint('📍 BatchSenderService: Retrying offline buffer send...');
        _sendOfflineBuffer();
      }
    });
  }

  /// Nettoyer les ressources
  @override
  Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;

    // Sauvegarder le batch courant dans le buffer offline
    if (_currentBatch.isNotEmpty) {
      _addBatchToOfflineBuffer(_currentBatch);
      _currentBatch.clear();
    }

    await _saveOfflineBuffer();
    _isInitialized = false;
    super.dispose();
  }

  /// Nettoyer le cache offline (utile pour supprimer les données corrompues)
  Future<void> clearOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bufferKey);
      _offlineBuffer.clear();
      _currentBatch.clear();
      debugPrint('📍 BatchSenderService: Offline cache cleared');
    } catch (e) {
      debugPrint('📍 BatchSenderService: Failed to clear offline cache: $e');
    }
  }

  /// Statistiques pour debug
  Map<String, dynamic> getStats() {
    return {
      'current_batch_size': _currentBatch.length,
      'offline_buffer_size': _offlineBuffer.length,
      'is_sending': _isSending,
      'is_initialized': _isInitialized,
    };
  }
}
