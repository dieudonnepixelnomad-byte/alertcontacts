import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('le reset backend préserve seulement l’URL API personnalisée', () async {
    SharedPreferences.setMockInitialValues({
      'base_url': 'https://staging.example.test/api',
      'bearer_token': 'obsolete-token',
      'user_profile': '{"id":"obsolete"}',
      'onboarding_done': true,
      'alert_event_store_v1': '[]',
      'app_review_successful_value_events': 3,
    });

    await PrefsService().resetForRecreatedBackendAccount();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString('base_url'), 'https://staging.example.test/api');
    expect(prefs.containsKey('bearer_token'), isFalse);
    expect(prefs.containsKey('user_profile'), isFalse);
    expect(prefs.containsKey('onboarding_done'), isFalse);
    expect(prefs.containsKey('alert_event_store_v1'), isFalse);
    expect(prefs.containsKey('app_review_successful_value_events'), isFalse);
  });
}
