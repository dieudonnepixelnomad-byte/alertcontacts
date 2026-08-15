class PaywallTriggerService {
  // CDC §10.1 — tier Gratuit : 2 proches, 1 zone.
  // Le paywall se déclenche au 3ème proche et à la 2ème zone.
  static const int freeContactsLimit = 2;
  static const int freeZonesLimit = 1;

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

}
