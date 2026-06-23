import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _config = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  static const Map<String, dynamic> _defaults = {
    'paywall_enabled': true,
    'community_alerts_enabled': true,
    'invisible_mode_duration_options': '60,240,0',
    'min_app_version_android': '1.0.0',
    'min_app_version_ios': '1.0.0',
    'android_store_url': 'https://play.google.com/store/apps/details?id=com.alertcontacts.alertcontacts',
    'ios_store_url': 'https://apps.apple.com/app/alertcontacts/id0000000000',
    'location_update_interval_foreground': 10,
    'location_update_interval_background': 300,
    'free_tier_contacts_limit': 2,
    'free_tier_zones_limit': 1,
    'trial_duration_days': 7,
    'onboarding_skip_allowed': true,
  };

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _config.setDefaults(_defaults);
      await _config.fetchAndActivate();
      _initialized = true;
      log('RemoteConfigService: initialized');
    } catch (e) {
      log('RemoteConfigService: init failed, using defaults — $e');
      _initialized = true;
    }
  }

  bool get paywallEnabled => _config.getBool('paywall_enabled');
  bool get communityAlertsEnabled => _config.getBool('community_alerts_enabled');
  int get freeTierContactsLimit => _config.getInt('free_tier_contacts_limit');
  int get freeTierZonesLimit => _config.getInt('free_tier_zones_limit');
  int get locationIntervalForeground => _config.getInt('location_update_interval_foreground');
  int get locationIntervalBackground => _config.getInt('location_update_interval_background');
  int get trialDurationDays => _config.getInt('trial_duration_days');
  String get minAppVersionAndroid => _config.getString('min_app_version_android');
  String get minAppVersionIos => _config.getString('min_app_version_ios');
  String get androidStoreUrl => _config.getString('android_store_url');
  String get iosStoreUrl => _config.getString('ios_store_url');
}
