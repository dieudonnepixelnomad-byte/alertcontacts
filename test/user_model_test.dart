import 'package:alertcontacts/core/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un administrateur dispose de l’accès Premium sans tier payant', () {
    final user = User.fromJson({
      'id': 1,
      'email': 'admin@example.com',
      'name': 'Admin',
      'tier': 'free',
      'is_admin': true,
    });

    expect(user.isPaidTier, isFalse);
    expect(user.hasPremiumAccess, isTrue);
  });
}
