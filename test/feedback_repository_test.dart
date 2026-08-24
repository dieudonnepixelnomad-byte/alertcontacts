import 'dart:convert';

import 'package:alertcontacts/core/repositories/feedback_repository.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('envoie le contrat attendu par l’API de feedback', () async {
    SharedPreferences.setMockInitialValues({'bearer_token': 'test-token'});
    final receivedRequest = <String, dynamic>{};
    final repository = FeedbackRepository(
      prefs: PrefsService(),
      client: MockClient((request) async {
        receivedRequest['method'] = request.method;
        receivedRequest['path'] = request.url.path;
        receivedRequest['authorization'] = request.headers['authorization'];
        receivedRequest['body'] = jsonDecode(request.body);
        return http.Response('{"success": true}', 201);
      }),
    );

    await repository.submitFeedback(
      category: 'bug',
      subject: 'La carte ne se charge pas',
      message: 'La carte reste vide après plusieurs tentatives.',
      appVersion: '4.1.1+49',
      osVersion: 'Android 15',
    );

    expect(receivedRequest['method'], 'POST');
    expect(receivedRequest['path'], '/feedback');
    expect(receivedRequest['authorization'], 'Bearer test-token');
    expect(receivedRequest['body'], {
      'type': 'bug',
      'subject': 'La carte ne se charge pas',
      'message': 'La carte reste vide après plusieurs tentatives.',
      'app_version': '4.1.1+49',
      'device_info': 'Android 15',
    });
  });
}
