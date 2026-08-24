import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'analytics_service.dart';

/// Client HTTP qui capture automatiquement toutes les erreurs réseau
/// et les statuts 4xx/5xx dans Crashlytics.
/// Remplace http.Client() dans tous les services API.
class AppHttpClient extends http.BaseClient {
  static void Function(String storeUrl)? onRequiredUpdate;
  static Future<PackageInfo>? _packageInfo;
  final http.Client _inner;

  AppHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final packageInfo = await (_packageInfo ??= PackageInfo.fromPlatform());
    request.headers.putIfAbsent('X-App-Version', () => packageInfo.version);
    request.headers.putIfAbsent('X-App-Build', () => packageInfo.buildNumber);
    request.headers.putIfAbsent(
      'X-App-Platform',
      () => Platform.isIOS ? 'ios' : 'android',
    );
    final label = '${request.method} ${request.url.path}';
    AnalyticsService().addBreadcrumb('http: $label');
    try {
      final response = await _inner.send(request);
      if (response.statusCode == 426) {
        onRequiredUpdate?.call(response.headers['x-update-store-url'] ?? '');
      }
      if (response.statusCode >= 400) {
        AnalyticsService().recordError(
          Exception('HTTP ${response.statusCode}'),
          StackTrace.current,
          reason: label,
        );
      }
      return response;
    } catch (e, stack) {
      AnalyticsService().recordError(e, stack, reason: 'network: $label');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
