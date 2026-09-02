import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductAnalyticsConfig {
  const ProductAnalyticsConfig({
    required this.projectApiKey,
    required this.host,
    required this.enabled,
  });

  factory ProductAnalyticsConfig.fromEnv() {
    final key = dotenv.maybeGet('POSTHOG_PROJECT_API_KEY')?.trim() ?? '';
    final host = dotenv.maybeGet('POSTHOG_HOST')?.trim() ?? '';

    return ProductAnalyticsConfig(
      projectApiKey: key,
      host: host.isEmpty ? 'https://us.i.posthog.com' : host,
      enabled: key.isNotEmpty,
    );
  }

  final String projectApiKey;
  final String host;
  final bool enabled;

  bool get debug => kDebugMode;
}
