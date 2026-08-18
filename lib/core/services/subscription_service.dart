import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Unique source client des droits RevenueCat.
///
/// Le serveur reste l'autorité pour les appels protégés : ce service permet
/// seulement de rendre l'interface immédiatement cohérente avec l'achat.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();
  static const entitlementId = 'premium';
  static const offeringId = 'default';
  static const monthlyProductId = 'premium_monthly';
  static const annualProductId = 'premium_annual';

  bool _configured = false;
  Future<void>? _initialization;
  bool _loading = false;
  String? _appUserId;
  String? _error;
  CustomerInfo? _customerInfo;
  Offering? _offering;

  bool get isLoading => _loading;
  bool get isConfigured => _configured;
  String? get error => _error;
  CustomerInfo? get customerInfo => _customerInfo;
  Offering? get offering => _offering;
  bool get isPremium =>
      _customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;
  bool get purchasesAvailable => Platform.isAndroid && _configured;

  Future<void> syncAppUserId(String? firebaseUid) async {
    await _initialize();
    if (!_configured || firebaseUid == _appUserId) return;

    _setLoading(true);
    try {
      if (firebaseUid == null) {
        final info = await Purchases.logOut();
        _applyCustomerInfo(info);
      } else {
        final result = await Purchases.logIn(firebaseUid);
        _applyCustomerInfo(result.customerInfo);
      }
      _appUserId = firebaseUid;
      _error = null;
    } catch (_) {
      _error = 'Impossible de synchroniser votre abonnement. Réessayez plus tard.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await _initialize();
    if (!_configured) return;

    _setLoading(true);
    try {
      _applyCustomerInfo(await Purchases.getCustomerInfo());
      await _loadOffering();
      _error = null;
    } catch (_) {
      _error = 'Les offres sont indisponibles pour le moment.';
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerInfo?> purchase(Package package) async {
    await _initialize();
    if (!_configured) return null;

    _setLoading(true);
    try {
      final result = await Purchases.purchasePackage(package);
      _applyCustomerInfo(result.customerInfo);
      _error = null;
      return result.customerInfo;
    } catch (_) {
      _error = 'Le paiement n’a pas abouti. Vérifiez votre connexion puis réessayez.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    await _initialize();
    if (!_configured) return null;

    _setLoading(true);
    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      _error = null;
      return info;
    } catch (_) {
      _error = 'Impossible de restaurer les achats pour le moment.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openManagement() async {
    final managementUrl = _customerInfo?.managementURL;
    if (managementUrl == null || managementUrl.isEmpty) {
      _error = 'Le lien de gestion de l’abonnement est indisponible.';
      notifyListeners();
      return;
    }
    await launchUrl(Uri.parse(managementUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _initialize() async {
    if (_configured || !Platform.isAndroid) return;

    _initialization ??= _initializeOnce();
    await _initialization;
  }

  Future<void> _initializeOnce() async {

    final apiKey = dotenv.env['REVENUECAT_ANDROID_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      _error = 'Les paiements Premium ne sont pas encore configurés.';
      notifyListeners();
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      _configured = true;
      await refresh();
    } catch (_) {
      _error = 'Les paiements Premium ne sont pas disponibles pour le moment.';
      notifyListeners();
    }
  }

  Future<void> _loadOffering() async {
    final offerings = await Purchases.getOfferings();
    _offering = offerings.all[offeringId] ?? offerings.current;
    if (_offering == null) {
      _error = 'Aucune offre Premium n’est disponible actuellement.';
    }
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
