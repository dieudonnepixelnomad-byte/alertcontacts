import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._();
  factory CrashReportingService() => _instance;
  CrashReportingService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> setUser(String userId) =>
      _crashlytics.setUserIdentifier(userId);

  Future<void> clearUser() => _crashlytics.setUserIdentifier('');

  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) =>
      _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  Future<void> log(String message) => _crashlytics.log(message);
}
