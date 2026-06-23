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
  }

  Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
    await _crashlytics.setUserIdentifier('');
    await _crashlytics.setCustomKey('user_email', '');
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  void logAuthStarted(String method) =>
      _fire(_analytics.logEvent(
        name: 'auth_started',
        parameters: {'method': method},
      ));

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

  // ── Screen tracking ───────────────────────────────────────────────────────

  void logScreenView(String screenName) =>
      _fire(_analytics.logScreenView(screenName: screenName));

  // ── Onboarding ────────────────────────────────────────────────────────────

  void logOnboardingStarted() =>
      _fire(_analytics.logEvent(name: 'onboarding_started'));

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

  void logInvitationScreenViewed() =>
      _fire(_analytics.logEvent(name: 'invitation_screen_viewed'));

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

  void logAppShellReached() =>
      _fire(_analytics.logEvent(name: 'app_shell_reached'));

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

  // ── Aha Moments ───────────────────────────────────────────────────────────

  void logAha1ContactAccepted() =>
      _fire(_analytics.logEvent(name: 'aha_1_contact_accepted'));

  void logAha2ContactOnMap() =>
      _fire(_analytics.logEvent(name: 'aha_2_contact_on_map'));

  void logAha3ZoneAlertReceived() =>
      _fire(_analytics.logEvent(name: 'aha_3_zone_alert_received'));

  // ── Contacts ──────────────────────────────────────────────────────────────

  void logContactInvited() =>
      _fire(_analytics.logEvent(name: 'contact_invited'));

  void logContactInvitationAccepted() =>
      _fire(_analytics.logEvent(name: 'contact_invitation_accepted'));

  void logContactRemoved() =>
      _fire(_analytics.logEvent(name: 'contact_removed'));

  // ── Zones ─────────────────────────────────────────────────────────────────

  void logZoneCreated({required String icon, required int radius}) =>
      _fire(_analytics.logEvent(
        name: 'zone_created',
        parameters: {'icon': icon, 'radius': radius},
      ));

  void logZoneEntryDetected() =>
      _fire(_analytics.logEvent(name: 'zone_entry_detected'));

  void logZoneExitDetected() =>
      _fire(_analytics.logEvent(name: 'zone_exit_detected'));

  // ── Community alerts ──────────────────────────────────────────────────────

  void logCommunityAlertViewed({required String gravity}) =>
      _fire(_analytics.logEvent(
        name: 'community_alert_viewed',
        parameters: {'gravity': gravity},
      ));

  void logCommunityAlertCreated({required String gravity, required String type}) =>
      _fire(_analytics.logEvent(
        name: 'community_alert_created',
        parameters: {'gravity': gravity, 'type': type},
      ));

  void logCommunityAlertConfirmed() =>
      _fire(_analytics.logEvent(name: 'community_alert_confirmed'));

  // ── Monetisation ─────────────────────────────────────────────────────────

  void logPaywallDisplayed({required String trigger}) =>
      _fire(_analytics.logEvent(
        name: 'paywall_displayed',
        parameters: {'trigger': trigger},
      ));

  void logPaywallDismissed() =>
      _fire(_analytics.logEvent(name: 'paywall_dismissed'));

  void logSubscriptionTrialStarted({required String tier, required String billing}) =>
      _fire(_analytics.logEvent(
        name: 'subscription_trial_started',
        parameters: {'tier': tier, 'billing': billing},
      ));

  void logSubscriptionPurchased({required String tier, required String billing}) =>
      _fire(_analytics.logEvent(
        name: 'subscription_purchased',
        parameters: {'tier': tier, 'billing': billing},
      ));

  void logSubscriptionCancelled({required String tier}) =>
      _fire(_analytics.logEvent(
        name: 'subscription_cancelled',
        parameters: {'tier': tier},
      ));

  void setUserTier(String tier) =>
      _fire(_analytics.setUserProperty(name: 'subscription_tier', value: tier));

  void setProfileType(String profileType) =>
      _fire(_analytics.setUserProperty(name: 'profile_type', value: profileType));

  void setHasActiveContact(bool value) =>
      _fire(_analytics.setUserProperty(
        name: 'has_active_contact',
        value: value ? 'true' : 'false',
      ));

  // ── Géolocalisation ───────────────────────────────────────────────────────

  void logLocationPermissionGranted() =>
      _fire(_analytics.logEvent(name: 'location_permission_granted'));

  void logLocationPermissionDenied() =>
      _fire(_analytics.logEvent(name: 'location_permission_denied'));

  void logInvisibleModeActivated({required int durationMinutes}) =>
      _fire(_analytics.logEvent(
        name: 'invisible_mode_activated',
        parameters: {'duration': durationMinutes.toString()},
      ));

  // ── Engagement ────────────────────────────────────────────────────────────

  void logNotificationOpened({required String type}) =>
      _fire(_analytics.logEvent(
        name: 'notification_opened',
        parameters: {'type': type},
      ));

  void logAppOpenedFromBackground() =>
      _fire(_analytics.logEvent(name: 'app_opened_from_background'));
}
