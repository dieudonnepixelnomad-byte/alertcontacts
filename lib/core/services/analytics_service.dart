import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;
  final _crashlytics = FirebaseCrashlytics.instance;
  final _performance = FirebasePerformance.instance;

  void _fire(Future<void> fn) => fn.catchError((Object _) {});

  // ── Identity ──────────────────────────────────────────────────────────────

  Future<void> setUser(String userId, {String? email}) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
    if (email != null) await _crashlytics.setCustomKey('user_email', email);
  }

  Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
    await _crashlytics.setUserIdentifier('');
    await _crashlytics.setCustomKey('user_email', '');
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  void logLoginSuccess(String method) =>
      _fire(_analytics.logLogin(loginMethod: method));

  void logSignUp(String method) =>
      _fire(_analytics.logSignUp(signUpMethod: method));

  void logLoginFailure({required String method, required String errorCode}) {
    _fire(_analytics.logEvent(
      name: 'login_failure',
      parameters: {'method': method, 'error_code': errorCode},
    ));
    _fire(_crashlytics.setCustomKey('last_auth_error', '$method:$errorCode'));
  }

  void logLogout() => _fire(_analytics.logEvent(name: 'logout'));

  void logPasswordReset() =>
      _fire(_analytics.logEvent(name: 'password_reset_requested'));

  // ── Onboarding ────────────────────────────────────────────────────────────

  void logOnboardingSlideViewed(int index) => _fire(
        _analytics.logEvent(
          name: 'onboarding_slide_viewed',
          parameters: {'slide_index': index},
        ),
      );

  void logOnboardingSlidesCompleted() =>
      _fire(_analytics.logEvent(name: 'onboarding_slides_completed'));

  void logOnboardingSlidesSkipped(int atSlide) => _fire(
        _analytics.logEvent(
          name: 'onboarding_slides_skipped',
          parameters: {'at_slide': atSlide},
        ),
      );

  void logOnboardingSandboxViewed() =>
      _fire(_analytics.logEvent(name: 'onboarding_sandbox_viewed'));

  void logOnboardingSandboxSkipped() =>
      _fire(_analytics.logEvent(name: 'onboarding_sandbox_skipped'));

  void logOnboardingAhaMomentTriggered(String dangerType) => _fire(
        _analytics.logEvent(
          name: 'onboarding_aha_moment_triggered',
          parameters: {'danger_type': dangerType},
        ),
      );

  void logOnboardingCelebrationViewed() =>
      _fire(_analytics.logEvent(name: 'onboarding_celebration_viewed'));

  void logOnboardingPersonaSelected(String persona) => _fire(
        _analytics.logEvent(
          name: 'onboarding_persona_selected',
          parameters: {'persona': persona},
        ),
      );

  void logOnboardingInvitationSent() =>
      _fire(_analytics.logEvent(name: 'onboarding_invitation_sent'));

  void logOnboardingInvitationSkipped() =>
      _fire(_analytics.logEvent(name: 'onboarding_invitation_skipped'));

  void logPermissionResult({required String type, required bool granted}) {
    _fire(_analytics.logEvent(
      name: 'permission_result',
      parameters: {
        'permission_type': type,
        'granted': granted ? 'true' : 'false',
      },
    ));
    _fire(_crashlytics.setCustomKey(
        'perm_$type', granted ? 'granted' : 'denied'));
  }

  void logOnboardingZoneCreated() =>
      _fire(_analytics.logEvent(name: 'onboarding_zone_created'));

  void logOnboardingCompleted() {
    _fire(_analytics.logEvent(name: 'onboarding_completed'));
    _fire(_analytics.logTutorialComplete());
  }

  // ── Errors (non-fatals) ───────────────────────────────────────────────────

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) =>
      _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  void addBreadcrumb(String message) => _fire(_crashlytics.log(message));

  // ── Performance — HTTP traces ─────────────────────────────────────────────

  Future<HttpMetric> startHttpTrace(String url, HttpMethod method) async {
    final metric = _performance.newHttpMetric(url, method);
    await metric.start();
    return metric;
  }

  // ── Performance — custom traces ───────────────────────────────────────────

  Future<Trace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }
}
