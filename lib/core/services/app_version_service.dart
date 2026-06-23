import 'dart:developer';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'remote_config_service.dart';

class AppVersionService {
  final RemoteConfigService _remoteConfig;

  AppVersionService(this._remoteConfig);

  Future<({bool required, String storeUrl})> checkForceUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);
      final minString = Platform.isIOS
          ? _remoteConfig.minAppVersionIos
          : _remoteConfig.minAppVersionAndroid;
      final minimum = _parseVersion(minString);
      final storeUrl = Platform.isIOS
          ? _remoteConfig.iosStoreUrl
          : _remoteConfig.androidStoreUrl;

      final updateRequired = _compareVersions(current, minimum) < 0;

      log('AppVersionService: current=${info.version} min=$minString updateRequired=$updateRequired');
      return (required: updateRequired, storeUrl: storeUrl);
    } catch (e) {
      log('AppVersionService: check failed, skipping — $e');
      return (required: false, storeUrl: '');
    }
  }

  List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  int _compareVersions(List<int> a, List<int> b) {
    final len = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}
