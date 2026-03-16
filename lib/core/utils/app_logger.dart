import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'log_sanitizer.dart';

/// Service de Logging Structuré (JSON) et Console Jolie.
class AppLogger {
  AppLogger._privateConstructor();
  static final AppLogger _instance = AppLogger._privateConstructor();
  static AppLogger get i => _instance;

  final Logger _consoleLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  String _appVersion = 'Unknown';
  String _environment = 'development';

  /// À appeler au démarrage de l'app
  void init({String version = '1.0.0', String environment = 'development'}) {
    _appVersion = version;
    _environment = environment;
  }

  void trace(String message, [Map<String, dynamic>? data]) =>
      _log(Level.trace, message, data);
  void debug(String message, [Map<String, dynamic>? data]) =>
      _log(Level.debug, message, data);
  void info(String message, [Map<String, dynamic>? data]) =>
      _log(Level.info, message, data);
  void warning(String message, [Map<String, dynamic>? data]) =>
      _log(Level.warning, message, data);
  void error(String message, [Map<String, dynamic>? data]) =>
      _log(Level.error, message, data);
  void fatal(String message, [Map<String, dynamic>? data]) =>
      _log(Level.fatal, message, data);

  void _log(Level level, String message, Map<String, dynamic>? data) {
    // 1. Sanitisation (RGPD)
    final safeData = data != null
        ? LogSanitizer.sanitize(data)
        : <String, dynamic>{};

    // 2. Objet Structuré (JSON pour SIEM)
    final logEntry = {
      "timestamp": DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      ).format(DateTime.now().toUtc()),
      "level": level.name,
      "env": _environment,
      "message": message,
      "app_version": _appVersion,
      ...safeData,
    };

    // 3. Sortie Console
    if (level.index >= Level.error.index) {
      _consoleLogger.e(message, error: safeData);
    } else {
      _consoleLogger.d(message);
    }

    // 4. Sortie JSON (Pour piping vers fichier ou API)
    // Pour l'instant, on print, mais idéalement on envoie à un service externe
    print("JSON_LOG: ${jsonEncode(logEntry)}");
  }
}
