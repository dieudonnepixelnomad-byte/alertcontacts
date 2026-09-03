import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/product_analytics_config.dart';

class ProductAnalyticsService {
  static final ProductAnalyticsService _instance = ProductAnalyticsService._();
  factory ProductAnalyticsService() => _instance;
  ProductAnalyticsService._();

  static const _analyticsConsentKey = 'analytics_consent';

  bool _configured = false;
  bool _setupAttempted = false;
  String? _appVersion;
  String? _buildNumber;

  Future<void> initialize() async {
    if (_setupAttempted) return;
    _setupAttempted = true;

    final config = ProductAnalyticsConfig.fromEnv();
    if (!config.enabled) {
      log('PostHog disabled: POSTHOG_PROJECT_API_KEY is empty.');
      return;
    }

    final consentGranted = await _hasAnalyticsConsent();
    final posthogConfig = PostHogConfig(config.projectApiKey)
      ..host = config.host
      ..debug = config.debug
      ..optOut = !consentGranted
      ..captureApplicationLifecycleEvents = false
      ..capturePushNotificationOpened = false
      ..capturePushNotificationSubscriptions = false
      ..sessionReplay = false
      ..surveys = false
      ..preloadFeatureFlags = false
      ..sendFeatureFlagEvents = false;

    try {
      await Posthog().setup(posthogConfig);
      _configured = true;
      await _loadAppInfo();
      await setAnalyticsConsent(consentGranted);
      if (kDebugMode) {
        log(
          'PostHog setup complete: host=${config.host}, optOut=${!consentGranted}',
        );
      }
    } catch (error, stack) {
      _configured = false;
      log('PostHog setup failed: $error', stackTrace: stack);
    }
  }

  Future<void> setAnalyticsConsent(bool granted) async {
    if (!_configured) return;

    await _guard(() async {
      if (granted) {
        await Posthog().enable();
      } else {
        await Posthog().disable();
      }
      if (kDebugMode) {
        log('PostHog analytics ${granted ? 'enabled' : 'disabled'}');
      }
    });
  }

  Future<void> identify(
    String userId, {
    Map<String, Object>? userProperties,
  }) async {
    if (!_configured || !await _hasAnalyticsConsent()) return;

    await _guard(() async {
      await Posthog().identify(
        userId: userId,
        userProperties: _sanitize(userProperties ?? const {}),
      );
    });
  }

  Future<void> reset() async {
    if (!_configured) return;

    await _guard(() async {
      await Posthog().reset();
      await setAnalyticsConsent(await _hasAnalyticsConsent());
    });
  }

  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_configured || !await _hasAnalyticsConsent()) return;

    await _guard(() async {
      await Posthog().capture(
        eventName: eventName,
        properties: _baseProperties()..addAll(_sanitize(properties)),
      );
      if (kDebugMode) {
        log('PostHog event captured: $eventName');
      }
    });
  }

  Future<void> screen(String screenName) async {
    if (!_configured || !await _hasAnalyticsConsent()) return;

    await _guard(() async {
      await Posthog().screen(
        screenName: screenName,
        properties: _baseProperties(),
      );
      if (kDebugMode) {
        log('PostHog screen captured: $screenName');
      }
    });
  }

  Future<void> setPersonProperties(Map<String, Object?> properties) async {
    if (!_configured || !await _hasAnalyticsConsent()) return;

    await _guard(() async {
      await Posthog().setPersonProperties(
        userPropertiesToSet: _sanitize(properties),
      );
    });
  }

  Map<String, Object> _baseProperties() {
    final properties = <String, Object>{'platform': _platform};
    final version = _appVersion;
    final build = _buildNumber;
    if (version != null) properties['app_version'] = version;
    if (build != null) properties['app_build'] = build;
    return properties;
  }

  Map<String, Object> _sanitize(Map<String, Object?> input) {
    final result = <String, Object>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      final value = entry.value;

      if (key.isEmpty || value == null || _isSensitiveKey(key)) continue;
      if (value is String && _looksSensitive(value)) continue;

      if (value is String || value is num || value is bool) {
        result[key] = value;
      }
    }
    return result;
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    if (normalized.startsWith('has_')) return false;

    const blockedFragments = [
      'email',
      'phone',
      'name',
      'nom',
      'prenom',
      'first_name',
      'last_name',
      'lat',
      'lng',
      'longitude',
      'latitude',
      'address',
      'adresse',
      'imei',
      'serial',
      'external_identifier',
      'identifier',
      'token',
      'secret',
      'password',
      'invite_url',
      'invitation_link',
    ];

    return blockedFragments.any(normalized.contains);
  }

  bool _looksSensitive(String value) {
    if (value.contains('@')) return true;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return true;
    }
    return false;
  }

  Future<bool> _hasAnalyticsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_analyticsConsentKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (_) {
      _appVersion = null;
      _buildNumber = null;
    }
  }

  Future<void> _guard(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (error, stack) {
      if (kDebugMode) {
        log('PostHog operation failed: $error', stackTrace: stack);
      }
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
