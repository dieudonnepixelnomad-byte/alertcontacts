class PaywallTriggerService {
  static const int freeContactsLimit = 3;
  static const int freeZonesLimit = 2;

  static bool checkContactLimit(int currentContactCount) {
    return currentContactCount >= freeContactsLimit;
  }

  static bool checkZoneLimit(int currentZoneCount) {
    return currentZoneCount >= freeZonesLimit;
  }

  static bool shouldShowProactive({
    required int activeContacts,
    required DateTime? installDate,
  }) {
    if (activeContacts < 2) return false;
    if (installDate == null) return false;
    return DateTime.now().difference(installDate).inDays >= 7;
  }

  // RevenueCat products not yet configured — always free tier
  static Future<bool> isPremium() async => false;
}
