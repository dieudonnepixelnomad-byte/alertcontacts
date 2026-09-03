import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:alertcontacts/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  AppVersionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<({bool required, String storeUrl})> checkForceUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/app-status'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        log('AppVersionService: app-status failed HTTP ${response.statusCode}');
        return (required: false, storeUrl: '');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final platformConfig =
          payload[Platform.isIOS ? 'ios' : 'android'] as Map<String, dynamic>?;
      if (platformConfig == null) {
        log('AppVersionService: missing platform config in app-status');
        return (required: false, storeUrl: '');
      }

      final minString = (platformConfig['min_version'] as String?) ?? '1.0.0';
      final minimumBuild = _parseBuild(platformConfig['minimum_build']);
      final minimum = _parseVersion(minString);
      final storeUrl = (platformConfig['store_url'] as String?) ?? '';

      final versionTooOld = _compareVersions(current, minimum) < 0;
      final buildTooOld = minimumBuild > 0 && currentBuild < minimumBuild;
      final updateRequired = versionTooOld || buildTooOld;

      log(
        'AppVersionService: current=${info.version}+${info.buildNumber} '
        'min=$minString+$minimumBuild updateRequired=$updateRequired',
      );
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

  int _parseBuild(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
