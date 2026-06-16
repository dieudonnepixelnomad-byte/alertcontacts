import 'dart:developer';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/revenuecat_config.dart';

class RevenueCatService {
  static RevenueCatService? _instance;
  static RevenueCatService get instance => _instance ??= RevenueCatService._();
  RevenueCatService._();

  // ─── Initialisation ────────────────────────────────────────────────────────

  Future<void> configure() async {
    try {
      final apiKey = Platform.isIOS
          ? RevenueCatConfig.apiKeyIOS
          : RevenueCatConfig.apiKeyAndroid;
      await Purchases.configure(PurchasesConfiguration(apiKey));
    } catch (e) {
      log('RevenueCatService.configure error: $e');
    }
  }

  // ─── Identification utilisateur ────────────────────────────────────────────

  Future<void> identifyUser(String firebaseUid) async {
    try {
      await Purchases.logIn(firebaseUid);
    } catch (e) {
      log('RevenueCatService.identifyUser error: $e');
    }
  }

  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      log('RevenueCatService.logoutUser error: $e');
    }
  }

  // ─── Statut abonnement ──────────────────────────────────────────────────────

  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(RevenueCatConfig.entitlementPremium);
    } catch (e) {
      log('RevenueCatService.isPremium error: $e');
      return false;
    }
  }

  Future<String?> getSubscriptionTier() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.activeSubscriptions;
      if (active.any((id) => id.contains('famille'))) return 'famille';
      if (active.any((id) => id.contains('solo'))) return 'solo';
      return null;
    } catch (e) {
      log('RevenueCatService.getSubscriptionTier error: $e');
      return null;
    }
  }

  // ─── Offerings & Packages ──────────────────────────────────────────────────

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      log('RevenueCatService.getOfferings error: $e');
      return null;
    }
  }

  Package? findPackage(List<Package> packages, String productId) {
    try {
      return packages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Achat ─────────────────────────────────────────────────────────────────

  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } catch (e) {
      if (e is PurchasesError &&
          e.code == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      log('RevenueCatService.purchasePackage error: $e');
      rethrow;
    }
  }

  // ─── Restauration ──────────────────────────────────────────────────────────

  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }
}
