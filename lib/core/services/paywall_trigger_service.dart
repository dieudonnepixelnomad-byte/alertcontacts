import 'package:flutter/foundation.dart';

import 'subscription_service.dart';

class PaywallTriggerService {
  // CDC §10.1 — tier Gratuit : 2 proches, 1 zone.
  // Le paywall se déclenche au 3ème proche et à la 2ème zone.
  static const int freeContactsLimit = 1;
  static const int freeZonesLimit = 1;

  static bool checkContactLimit(int currentContactCount) {
    final premium =
        SubscriptionService.instance.hasPremiumAccess('multi_contacts');
    final shouldShow = !premium && currentContactCount >= freeContactsLimit;
    _logGate(
      feature: 'multi_contacts',
      premium: premium,
      currentCount: currentContactCount,
      limit: freeContactsLimit,
      shouldShowPaywall: shouldShow,
    );
    return shouldShow;
  }

  static bool checkZoneLimit(int currentZoneCount) {
    final premium =
        SubscriptionService.instance.hasPremiumAccess('unlimited_zones');
    final shouldShow = !premium && currentZoneCount >= freeZonesLimit;
    _logGate(
      feature: 'unlimited_zones',
      premium: premium,
      currentCount: currentZoneCount,
      limit: freeZonesLimit,
      shouldShowPaywall: shouldShow,
    );
    return shouldShow;
  }

  static bool shouldShowProactive({
    required int activeContacts,
    required DateTime? installDate,
  }) {
    if (activeContacts < 2) return false;
    if (installDate == null) return false;
    return DateTime.now().difference(installDate).inDays >= 7;
  }

  static void _logGate({
    required String feature,
    required bool premium,
    required int currentCount,
    required int limit,
    required bool shouldShowPaywall,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Paywall] feature=$feature, premium=$premium, count=$currentCount, '
      'freeLimit=$limit, decision=${shouldShowPaywall ? 'show_paywall' : 'allow_access'}',
    );
  }
}
