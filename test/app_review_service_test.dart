import 'package:alertcontacts/core/services/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late DateTime currentTime;
  late AppReviewService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    currentTime = DateTime(2026, 1, 1);
    service = AppReviewService(
      preferences: preferences,
      now: () => currentTime,
    );
    await service.initialize();
  });

  test('ne sollicite pas avant sept jours et trois succès métier', () async {
    currentTime = currentTime.add(const Duration(days: 8));

    expect(await service.registerSuccessfulValueEvent(), isFalse);
    expect(await service.registerSuccessfulValueEvent(), isFalse);
    expect(await service.registerSafetyAhaMoment(), isTrue);
  });

  test('suspend la demande après une erreur récente', () async {
    currentTime = currentTime.add(const Duration(days: 8));
    await service.registerSuccessfulValueEvent();
    await service.registerSuccessfulValueEvent();
    await service.registerSafetyAhaMoment();
    expect(await service.isEligible(), isTrue);

    await service.recordRecentError();
    expect(await service.isEligible(), isFalse);

    currentTime = currentTime.add(AppReviewService.errorQuietPeriod);
    expect(await service.isEligible(), isTrue);
  });
}
