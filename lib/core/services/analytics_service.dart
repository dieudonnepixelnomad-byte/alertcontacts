import 'crash_reporting_service.dart';
import 'product_analytics_service.dart';

enum HttpMethod { get, post, put, delete, patch }

class NoopHttpMetric {
  int? httpResponseCode;

  Future<void> stop() async {}
}

class NoopTrace {
  Future<void> stop() async {}
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final _product = ProductAnalyticsService();
  final _crash = CrashReportingService();

  void _fire(Future<void> fn) => fn.catchError((Object _) {});

  Future<void> initializeProductAnalytics() => _product.initialize();

  Future<void> setUser(String userId, {String? email}) async {
    await _crash.setUser(userId);
    await _product.identify(userId);
  }

  Future<void> clearUser() async {
    await _crash.clearUser();
    await _crash.setCustomKey('user_email', '');
    await _product.reset();
  }

  void logAuthStarted(String method) =>
      _capture('auth_started', {'method': method});

  void logLoginSuccess(String method) =>
      _capture('login_success', {'method': method});

  void logSignUp(String method) =>
      _capture('signup_success', {'method': method});

  void logLoginFailure({required String method, required String errorCode}) {
    _capture('login_failure', {'method': method, 'error_code': errorCode});
    _fire(_crash.setCustomKey('last_auth_error', '$method:$errorCode'));
  }

  void logLogout() => _capture('logout');

  void logPasswordReset() => _capture('password_reset_requested');

  void logScreenView(String screenName) => _fire(_product.screen(screenName));

  void logOnboardingStarted() => _capture('onboarding_started');

  void logOnboardingSlideViewed(int index) =>
      _capture('onboarding_slide_viewed', {'slide_index': index});

  void logOnboardingSlidesCompleted() =>
      _capture('onboarding_slides_completed');

  void logOnboardingSlidesSkipped(int atSlide) =>
      _capture('onboarding_slides_skipped', {'at_slide': atSlide});

  void logOnboardingSandboxViewed() => _capture('onboarding_sandbox_viewed');

  void logOnboardingSandboxSkipped() => _capture('onboarding_sandbox_skipped');

  void logOnboardingAhaMomentTriggered(String dangerType) =>
      _capture('onboarding_aha_moment_triggered', {'danger_type': dangerType});

  void logOnboardingCelebrationViewed() =>
      _capture('onboarding_celebration_viewed');

  void logOnboardingPersonaSelected(String persona) {
    _capture('onboarding_persona_selected', {'persona': persona});
    setProfileType(persona);
  }

  void logInvitationScreenViewed() => _capture('invitation_screen_viewed');

  void logOnboardingInvitationSent() => _capture('onboarding_invitation_sent');

  void logOnboardingInvitationSkipped() =>
      _capture('onboarding_invitation_skipped');

  void logPermissionResult({required String type, required bool granted}) {
    _capture('permission_result', {
      'permission_type': type,
      'granted': granted,
    });
    _fire(_crash.setCustomKey('perm_$type', granted ? 'granted' : 'denied'));
  }

  void logOnboardingZoneCreated() => _capture('onboarding_zone_created');

  void logAppShellReached() => _capture('app_shell_reached');

  void logOnboardingCompleted() => _capture('onboarding_completed');

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _crash.recordError(error, stack, reason: reason, fatal: fatal);

  void addBreadcrumb(String message) => _fire(_crash.log(message));

  Future<NoopHttpMetric> startHttpTrace(String url, HttpMethod method) async =>
      NoopHttpMetric();

  Future<NoopTrace> startTrace(String name) async => NoopTrace();

  void logAha1ContactAccepted() => _capture('aha_1_contact_accepted');

  void logAha2ContactOnMap() => _capture('aha_2_contact_on_map');

  void logAha3ZoneAlertReceived() => _capture('aha_3_zone_alert_received');

  void logSafetyAhaMomentConfirmed() => _capture('safety_aha_moment_confirmed');

  void logContactInvited() => _capture('contact_invited');

  void logContactInvitationAccepted() =>
      _capture('contact_invitation_accepted');

  void logContactRemoved() => _capture('contact_removed');

  void logZoneCreated({required String icon, required int radius}) => _capture(
    'zone_created',
    {'icon': icon, 'radius_bucket': _radiusBucket(radius)},
  );

  void logZoneEntryDetected() => _capture('zone_entry_detected');

  void logZoneExitDetected() => _capture('zone_exit_detected');

  void logCommunityAlertViewed({required String gravity}) =>
      _capture('community_alert_viewed', {'gravity': gravity});

  void logCommunityAlertCreated({
    required String gravity,
    required String type,
  }) => _capture('community_alert_created', {'gravity': gravity, 'type': type});

  void logCommunityAlertConfirmed() => _capture('community_alert_confirmed');

  void logRoutePreviewed({
    required String transportMode,
    required int incidentCount,
  }) => _capture('route_previewed', {
    'transport_mode': transportMode,
    'incident_count': incidentCount,
  });

  void logRouteIncidentDetected({
    required String gravity,
    required String type,
    required int reportCount,
  }) => _capture('route_incident_detected', {
    'gravity': gravity,
    'type': type,
    'report_count_bucket': _countBucket(reportCount),
  });

  void logRouteAvoidanceRequested({required int incidentCount}) =>
      _capture('route_avoidance_requested', {'incident_count': incidentCount});

  void logRouteAvoidancePartial() => _capture('route_avoidance_partial');

  void logRouteStarted({
    required String transportMode,
    required bool avoidanceApplied,
  }) => _capture('route_started', {
    'transport_mode': transportMode,
    'avoidance_applied': avoidanceApplied,
  });

  void logRouteIncidentNotificationOpened() =>
      _capture('route_incident_notification_opened');

  void logPaywallDisplayed({required String trigger}) =>
      _capture('paywall_displayed', {'trigger': trigger});

  void logPaywallDismissed() => _capture('paywall_dismissed');

  void logSubscriptionTrialStarted({
    required String tier,
    required String billing,
  }) => _capture('subscription_trial_started', {
    'tier': tier,
    'billing': billing,
  });

  void logSubscriptionPurchased({
    required String tier,
    required String billing,
  }) {
    _capture('subscription_purchased', {'tier': tier, 'billing': billing});
    setUserTier(tier);
  }

  void logSubscriptionCancelled({required String tier}) =>
      _capture('subscription_cancelled', {'tier': tier});

  void setUserTier(String tier) =>
      _fire(_product.setPersonProperties({'subscription_tier': tier}));

  void setProfileType(String profileType) =>
      _fire(_product.setPersonProperties({'profile_type': profileType}));

  void setHasActiveContact(bool value) =>
      _fire(_product.setPersonProperties({'has_active_contact': value}));

  void logLocationPermissionGranted() =>
      logPermissionResult(type: 'location', granted: true);

  void logLocationPermissionDenied() =>
      logPermissionResult(type: 'location', granted: false);

  void logInvisibleModeActivated({required int durationMinutes}) => _capture(
    'invisible_mode_activated',
    {'duration_bucket': _durationBucket(durationMinutes)},
  );

  void logNotificationOpened({required String type}) =>
      _capture('notification_opened', {'type': type});

  void logAppOpenedFromBackground() => _capture('app_opened_from_background');

  void logAppReviewPrompt({required String action}) =>
      _capture('app_review_prompt', {'action': action});

  void logTrackerAdded({
    required bool hasProvider,
    required bool hasIdentifier,
  }) => _capture('tracker_added', {
    'has_provider': hasProvider,
    'has_identifier': hasIdentifier,
  });

  void logTrackerActivationStarted({required String status}) =>
      _capture('tracker_activation_started', {'tracker_status': status});

  void logTrackerActivated() => _capture('tracker_activated');

  void logTrackerActivationFailed({required String reason}) =>
      _capture('tracker_activation_failed', {'reason': reason});

  void logTrackerSuspended({required String reason}) =>
      _capture('tracker_suspended', {'reason': reason});

  void _capture(
    String eventName, [
    Map<String, Object?> properties = const {},
  ]) {
    _fire(_product.capture(eventName, properties: properties));
  }

  String _radiusBucket(int radius) {
    if (radius < 100) return '<100m';
    if (radius <= 200) return '100-200m';
    if (radius <= 500) return '201-500m';
    return '>500m';
  }

  String _durationBucket(int minutes) {
    if (minutes <= 60) return '<=1h';
    if (minutes <= 240) return '1-4h';
    return '>4h';
  }

  String _countBucket(int count) {
    if (count <= 1) return '1';
    if (count <= 3) return '2-3';
    return '4+';
  }
}
