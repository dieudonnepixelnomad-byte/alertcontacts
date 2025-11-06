import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

/// Service de métriques de performance pour surveiller les services critiques
class PerformanceMetrics {
  static final PerformanceMetrics _instance = PerformanceMetrics._internal();
  factory PerformanceMetrics() => _instance;
  PerformanceMetrics._internal();

  final Map<String, _ServiceMetrics> _serviceMetrics = {};
  final Map<String, DateTime> _operationStartTimes = {};
  Timer? _reportTimer;

  /// Initialise le service de métriques
  void initialize() {
    if (kDebugMode) {
      // Rapport automatique toutes les 5 minutes en mode debug
      _reportTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _generatePerformanceReport();
      });
      log('PerformanceMetrics: Service initialisé');
    }
  }

  /// Enregistre le démarrage d'un service
  void recordServiceStart(String serviceName) {
    _serviceMetrics[serviceName] ??= _ServiceMetrics(serviceName);
    _serviceMetrics[serviceName]!.recordStart();
    log('PerformanceMetrics: Service $serviceName démarré');
  }

  /// Enregistre l'arrêt d'un service
  void recordServiceStop(String serviceName) {
    _serviceMetrics[serviceName]?.recordStop();
    log('PerformanceMetrics: Service $serviceName arrêté');
  }

  /// Enregistre une erreur de service
  void recordServiceError(String serviceName, String errorType) {
    _serviceMetrics[serviceName]?.recordError(errorType);
    log('PerformanceMetrics: Erreur dans $serviceName - $errorType');
  }

  /// Démarre la mesure d'une opération
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// Termine la mesure d'une opération et enregistre la durée
  void endOperation(String operationName, {String? serviceName}) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _recordOperationDuration(operationName, duration, serviceName);
    }
  }

  /// Enregistre une métrique personnalisée
  void recordCustomMetric(String metricName, double value, {String? unit}) {
    if (kDebugMode) {
      log('PerformanceMetrics: $metricName = $value ${unit ?? ''}');
    }
  }

  /// Enregistre l'utilisation mémoire
  void recordMemoryUsage(String serviceName, int memoryBytes) {
    _serviceMetrics[serviceName]?.recordMemoryUsage(memoryBytes);
  }

  /// Enregistre la consommation batterie (estimation)
  void recordBatteryImpact(String serviceName, double impactPercentage) {
    _serviceMetrics[serviceName]?.recordBatteryImpact(impactPercentage);
  }

  /// Enregistre une opération de géolocalisation
  void recordGeolocationUpdate(double accuracy, int satelliteCount) {
    recordCustomMetric('gps_accuracy', accuracy, unit: 'm');
    recordCustomMetric('gps_satellites', satelliteCount.toDouble());
    
    _serviceMetrics['geolocation'] ??= _ServiceMetrics('geolocation');
    _serviceMetrics['geolocation']!.recordGeolocationUpdate(accuracy);
  }

  /// Enregistre une notification envoyée
  void recordNotificationSent(String notificationType, bool success) {
    final serviceName = 'notifications';
    _serviceMetrics[serviceName] ??= _ServiceMetrics(serviceName);
    _serviceMetrics[serviceName]!.recordNotification(notificationType, success);
  }



  /// Obtient les métriques d'un service
  Map<String, dynamic> getServiceMetrics(String serviceName) {
    return _serviceMetrics[serviceName]?.toMap() ?? {};
  }

  /// Obtient toutes les métriques
  Map<String, dynamic> getAllMetrics() {
    final Map<String, dynamic> allMetrics = {};
    
    for (final entry in _serviceMetrics.entries) {
      allMetrics[entry.key] = entry.value.toMap();
    }
    
    return allMetrics;
  }

  /// Génère un rapport de performance
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== RAPPORT DE PERFORMANCE ===');
    buffer.writeln('Généré le: ${DateTime.now()}');
    buffer.writeln();

    for (final entry in _serviceMetrics.entries) {
      final metrics = entry.value;
      buffer.writeln('Service: ${entry.key}');
      buffer.writeln('  Uptime: ${metrics.getUptimeFormatted()}');
      buffer.writeln('  Redémarrages: ${metrics.restartCount}');
      buffer.writeln('  Erreurs: ${metrics.errorCount}');
      buffer.writeln('  Dernière erreur: ${metrics.lastError ?? 'Aucune'}');
      
      if (metrics.averageMemoryUsage > 0) {
        buffer.writeln('  Mémoire moyenne: ${(metrics.averageMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB');
      }
      
      if (metrics.totalBatteryImpact > 0) {
        buffer.writeln('  Impact batterie: ${metrics.totalBatteryImpact.toStringAsFixed(2)}%');
      }
      
      if (metrics.operationDurations.isNotEmpty) {
        final avgDuration = metrics.operationDurations.values
            .map((list) => list.reduce((a, b) => a + b) / list.length)
            .reduce((a, b) => a + b) / metrics.operationDurations.length;
        buffer.writeln('  Durée opération moyenne: ${avgDuration.toStringAsFixed(0)}ms');
      }
      
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Génère et affiche un rapport automatique
  void _generatePerformanceReport() {
    if (kDebugMode && _serviceMetrics.isNotEmpty) {
      final report = generateReport();
      log('PerformanceMetrics Report:\n$report');
    }
  }

  /// Enregistre la durée d'une opération
  void _recordOperationDuration(String operationName, Duration duration, String? serviceName) {
    final durationMs = duration.inMilliseconds;
    
    if (serviceName != null) {
      _serviceMetrics[serviceName] ??= _ServiceMetrics(serviceName);
      _serviceMetrics[serviceName]!.recordOperationDuration(operationName, durationMs);
    }
    
    if (kDebugMode) {
      log('PerformanceMetrics: $operationName completed in ${durationMs}ms');
    }
  }

  /// Nettoie les métriques anciennes
  void cleanup() {
    _operationStartTimes.clear();
    for (final metrics in _serviceMetrics.values) {
      metrics.cleanup();
    }
  }

  /// Dispose du service
  void dispose() {
    _reportTimer?.cancel();
    _reportTimer = null;
    cleanup();
  }
}

/// Classe pour stocker les métriques d'un service
class _ServiceMetrics {
  final String serviceName;
  DateTime? _startTime;
  DateTime? _stopTime;
  int restartCount = 0;
  int errorCount = 0;
  String? lastError;
  
  // Métriques de performance
  final List<int> memoryUsages = [];
  double totalBatteryImpact = 0.0;
  final Map<String, List<int>> operationDurations = {};
  
  // Métriques spécifiques
  final List<double> gpsAccuracies = [];
  final Map<String, int> notificationCounts = {};
  final Map<String, List<double>> alertDistances = {};

  _ServiceMetrics(this.serviceName);

  void recordStart() {
    if (_startTime != null && _stopTime == null) {
      restartCount++;
    }
    _startTime = DateTime.now();
    _stopTime = null;
  }

  void recordStop() {
    _stopTime = DateTime.now();
  }

  void recordError(String errorType) {
    errorCount++;
    lastError = '$errorType (${DateTime.now()})';
  }

  void recordMemoryUsage(int bytes) {
    memoryUsages.add(bytes);
    // Garder seulement les 100 dernières mesures
    if (memoryUsages.length > 100) {
      memoryUsages.removeAt(0);
    }
  }

  void recordBatteryImpact(double impact) {
    totalBatteryImpact += impact;
  }

  void recordOperationDuration(String operationName, int durationMs) {
    operationDurations[operationName] ??= [];
    operationDurations[operationName]!.add(durationMs);
    
    // Garder seulement les 50 dernières mesures par opération
    if (operationDurations[operationName]!.length > 50) {
      operationDurations[operationName]!.removeAt(0);
    }
  }

  void recordGeolocationUpdate(double accuracy) {
    gpsAccuracies.add(accuracy);
    if (gpsAccuracies.length > 100) {
      gpsAccuracies.removeAt(0);
    }
  }

  void recordNotification(String type, bool success) {
    final key = '${type}_${success ? 'success' : 'failed'}';
    notificationCounts[key] = (notificationCounts[key] ?? 0) + 1;
  }

  void recordAlert(String alertType, double distance) {
    alertDistances[alertType] ??= [];
    alertDistances[alertType]!.add(distance);
    
    if (alertDistances[alertType]!.length > 50) {
      alertDistances[alertType]!.removeAt(0);
    }
  }

  Duration get uptime {
    if (_startTime == null) return Duration.zero;
    final endTime = _stopTime ?? DateTime.now();
    return endTime.difference(_startTime!);
  }

  String getUptimeFormatted() {
    final duration = uptime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  double get averageMemoryUsage {
    if (memoryUsages.isEmpty) return 0.0;
    return memoryUsages.reduce((a, b) => a + b) / memoryUsages.length;
  }

  double get averageGpsAccuracy {
    if (gpsAccuracies.isEmpty) return 0.0;
    return gpsAccuracies.reduce((a, b) => a + b) / gpsAccuracies.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'service_name': serviceName,
      'uptime_seconds': uptime.inSeconds,
      'restart_count': restartCount,
      'error_count': errorCount,
      'last_error': lastError,
      'average_memory_mb': averageMemoryUsage / 1024 / 1024,
      'total_battery_impact': totalBatteryImpact,
      'average_gps_accuracy': averageGpsAccuracy,
      'notification_counts': notificationCounts,
      'operation_durations': operationDurations.map(
        (key, value) => MapEntry(
          key,
          value.isNotEmpty ? value.reduce((a, b) => a + b) / value.length : 0,
        ),
      ),
    };
  }

  void cleanup() {
    // Nettoyer les anciennes données pour éviter l'accumulation
    if (memoryUsages.length > 100) {
      memoryUsages.removeRange(0, memoryUsages.length - 100);
    }
    
    if (gpsAccuracies.length > 100) {
      gpsAccuracies.removeRange(0, gpsAccuracies.length - 100);
    }
    
    for (final key in operationDurations.keys.toList()) {
      if (operationDurations[key]!.length > 50) {
        operationDurations[key]!.removeRange(0, operationDurations[key]!.length - 50);
      }
    }
  }
}