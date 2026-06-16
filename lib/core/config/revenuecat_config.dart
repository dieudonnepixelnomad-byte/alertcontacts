class RevenueCatConfig {
  // API keys from RevenueCat Dashboard → App Settings
  static const String apiKeyIOS = 'appl_YOUR_REVENUECAT_IOS_KEY';
  static const String apiKeyAndroid = 'test_ZVgbOJSFYOGTFNYdKVujrmottXj';

  // Entitlement ID — configured in RevenueCat Dashboard → Entitlements
  static const String entitlementPremium = 'premium';

  // Offering identifier — configured in RevenueCat Dashboard → Offerings
  static const String offeringDefault = 'default';

  // Product IDs — must match App Store Connect and Google Play Console
  static const String productSoloMonthly = 'alertcontacts_solo_monthly';
  static const String productSoloAnnual = 'alertcontacts_solo_annual';
  static const String productFamilleMonthly = 'alertcontacts_famille_monthly';
  static const String productFamilleAnnual = 'alertcontacts_famille_annual';
}
