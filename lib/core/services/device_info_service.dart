import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v\${packageInfo.version} (build \${packageInfo.buildNumber})';
  }

  Future<String> getOsVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return 'Android \${androidInfo.version.release} (SDK \${androidInfo.version.sdkInt})';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return 'iOS \${iosInfo.systemVersion}';
    }
    return 'Unknown OS';
  }

  Future<Map<String, String>> getDeviceAndAppInfo() async {
    final appVersion = await getAppVersion();
    final osVersion = await getOsVersion();
    return {
      'appVersion': appVersion,
      'osVersion': osVersion,
    };
  }
}