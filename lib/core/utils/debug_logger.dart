import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Logger centralisé pour le debug en production
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static const int _maxLogEntries = 1000;
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final StreamController<LogEntry> _logStreamController = StreamController.broadcast();

  Stream<LogEntry> get logStream => _logStreamController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Log d'information générale
  void info(String tag, String message, [Map<String, dynamic>? data]) {
    _addLog(LogLevel.info, tag, message, data);
  }

  /// Log d'avertissement
  void warning(String tag, String message, [Map<String, dynamic>? data]) {
    _addLog(LogLevel.warning, tag, message, data);
  }

  /// Log d'erreur
  void error(String tag, String message, [Map<String, dynamic>? data, Object? error, StackTrace? stackTrace]) {
    _addLog(LogLevel.error, tag, message, data, error, stackTrace);
  }

  /// Log de debug (uniquement en mode debug)
  void debug(String tag, String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      _addLog(LogLevel.debug, tag, message, data);
    }
  }

  /// Log spécifique pour la géolocalisation
  void geolocation(String event, Map<String, dynamic> data) {
    _addLog(LogLevel.geolocation, 'GEOLOCATION', event, data);
  }

  /// Log spécifique pour les alertes
  void alert(String event, Map<String, dynamic> data) {
    _addLog(LogLevel.alert, 'ALERT', event, data);
  }

  /// Log spécifique pour les notifications
  void notification(String event, Map<String, dynamic> data) {
    _addLog(LogLevel.notification, 'NOTIFICATION', event, data);
  }

  /// Log spécifique pour les services en arrière-plan
  void background(String event, Map<String, dynamic> data) {
    _addLog(LogLevel.background, 'BACKGROUND', event, data);
  }

  void _addLog(LogLevel level, String tag, String message, [Map<String, dynamic>? data, Object? error, StackTrace? stackTrace]) {
    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Ajouter à la queue
    _logs.add(entry);
    
    // Limiter le nombre d'entrées
    while (_logs.length > _maxLogEntries) {
      _logs.removeFirst();
    }

    // Notifier les listeners
    _logStreamController.add(entry);

    // Log dans la console en mode debug
    if (kDebugMode) {
      final prefix = _getLevelPrefix(level);
      final timestamp = entry.timestamp.toIso8601String().substring(11, 23);
      print('$prefix [$timestamp] [$tag] $message');
      
      if (data != null && data.isNotEmpty) {
        print('  Data: $data');
      }
      
      if (error != null) {
        print('  Error: $error');
      }
      
      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
    }
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.geolocation:
        return '📍';
      case LogLevel.alert:
        return '🚨';
      case LogLevel.notification:
        return '🔔';
      case LogLevel.background:
        return '⚙️';
    }
  }

  /// Filtrer les logs par niveau
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Filtrer les logs par tag
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Filtrer les logs par période
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }

  /// Obtenir les logs récents (dernières X minutes)
  List<LogEntry> getRecentLogs(int minutes) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return _logs.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  /// Exporter les logs en format texte
  String exportLogs({LogLevel? level, String? tag, int? lastMinutes}) {
    List<LogEntry> logsToExport = _logs.toList();
    
    if (level != null) {
      logsToExport = logsToExport.where((log) => log.level == level).toList();
    }
    
    if (tag != null) {
      logsToExport = logsToExport.where((log) => log.tag == tag).toList();
    }
    
    if (lastMinutes != null) {
      final cutoff = DateTime.now().subtract(Duration(minutes: lastMinutes));
      logsToExport = logsToExport.where((log) => log.timestamp.isAfter(cutoff)).toList();
    }
    
    final buffer = StringBuffer();
    buffer.writeln('=== ALERTCONTACTS DEBUG LOGS ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logsToExport.length}');
    buffer.writeln('');
    
    for (final log in logsToExport) {
      buffer.writeln('${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] [${log.tag}] ${log.message}');
      
      if (log.data != null && log.data!.isNotEmpty) {
        buffer.writeln('  Data: ${log.data}');
      }
      
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      
      if (log.stackTrace != null) {
        buffer.writeln('  StackTrace: ${log.stackTrace}');
      }
      
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Vider tous les logs
  void clearLogs() {
    _logs.clear();
    info('LOGGER', 'Logs cleared');
  }

  /// Obtenir des statistiques sur les logs
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 1));
    
    final last24hLogs = _logs.where((log) => log.timestamp.isAfter(last24h)).toList();
    final lastHourLogs = _logs.where((log) => log.timestamp.isAfter(lastHour)).toList();
    
    return {
      'totalLogs': _logs.length,
      'last24hLogs': last24hLogs.length,
      'lastHourLogs': lastHourLogs.length,
      'errorCount': _logs.where((log) => log.level == LogLevel.error).length,
      'warningCount': _logs.where((log) => log.level == LogLevel.warning).length,
      'geolocationEvents': _logs.where((log) => log.level == LogLevel.geolocation).length,
      'alertEvents': _logs.where((log) => log.level == LogLevel.alert).length,
      'oldestLog': _logs.isNotEmpty ? _logs.first.timestamp.toIso8601String() : null,
      'newestLog': _logs.isNotEmpty ? _logs.last.timestamp.toIso8601String() : null,
    };
  }

  void dispose() {
    _logStreamController.close();
  }
}

/// Niveaux de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  geolocation,
  alert,
  notification,
  background,
}

/// Entrée de log
class LogEntry {
  final LogLevel level;
  final String tag;
  final String message;
  final Map<String, dynamic>? data;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    this.data,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LogEntry(level: $level, tag: $tag, message: $message, timestamp: $timestamp)';
  }
}

/// Extension pour faciliter l'utilisation
extension DebugLoggerExtension on Object {
  void logInfo(String message, [Map<String, dynamic>? data]) {
    DebugLogger().info(runtimeType.toString(), message, data);
  }

  void logWarning(String message, [Map<String, dynamic>? data]) {
    DebugLogger().warning(runtimeType.toString(), message, data);
  }

  void logError(String message, [Map<String, dynamic>? data, Object? error, StackTrace? stackTrace]) {
    DebugLogger().error(runtimeType.toString(), message, data, error, stackTrace);
  }

  void logDebug(String message, [Map<String, dynamic>? data]) {
    DebugLogger().debug(runtimeType.toString(), message, data);
  }
}