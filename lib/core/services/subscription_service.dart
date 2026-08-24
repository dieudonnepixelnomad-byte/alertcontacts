import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  /// Doit correspondre exactement à l'identifier configuré dans RevenueCat,
  /// pas à son display name. Peut différer entre Test Store et production.
  static String get entitlementId =>
      dotenv.env['REVENUECAT_ENTITLEMENT_ID']?.trim().isNotEmpty == true
      ? dotenv.env['REVENUECAT_ENTITLEMENT_ID']!.trim()
      : 'premium';
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
  bool _hasAdminAccess = false;

  bool get isLoading => _loading;
  bool get isConfigured => _configured;
  String? get error => _error;
  CustomerInfo? get customerInfo => _customerInfo;
  Offering? get offering => _offering;
  bool get hasAdminAccess => _hasAdminAccess;
  bool get isPremium =>
      _hasAdminAccess ||
      (_customerInfo?.entitlements.active.containsKey(entitlementId) ?? false);
  bool get purchasesAvailable => Platform.isAndroid && _configured;

  /// Contrôle client traçable des fonctionnalités Premium.
  /// Le serveur conserve la décision finale pour les API protégées.
  bool hasPremiumAccess(String feature) {
    final allowed = isPremium;
    _log(
      'Accès Premium: feature=$feature, entitlement=$entitlementId, '
      'decision=${allowed ? 'allow_access' : 'show_paywall'}',
    );
    return allowed;
  }

  /// Met à jour l'exemption accordée par le backend à un administrateur.
  /// Elle ne crée ni achat ni entitlement RevenueCat.
  void setAdminAccess(bool enabled) {
    if (_hasAdminAccess == enabled) return;
    _hasAdminAccess = enabled;
    _log('Accès administrateur: ${enabled ? 'activé' : 'désactivé'}');
    notifyListeners();
  }

  /// Etat non sensible pour vérifier RevenueCat en développement.
  /// Ne contient ni la clé RevenueCat ni l'identifiant Firebase.
  String get debugSnapshot {
    final entitlement = _customerInfo?.entitlements.active[entitlementId];
    return 'configured=$_configured, admin=$_hasAdminAccess, premium=$isPremium, '
        'offering=${_offering?.identifier ?? 'none'}, '
        'product=${entitlement?.productIdentifier ?? 'none'}, '
        'activeEntitlements=${_customerInfo?.entitlements.active.keys.join(',') ?? 'none'}, '
        'activeSubscriptions=${_customerInfo?.activeSubscriptions.join(',') ?? 'none'}, '
        'willRenew=${entitlement?.willRenew}, '
        'expiration=${entitlement?.expirationDate ?? 'none'}';
  }

  Future<void> syncAppUserId(String? firebaseUid) async {
    await _initialize();
    if (!_configured || firebaseUid == _appUserId) return;

    _log('Synchronisation du client RevenueCat: ${firebaseUid == null ? 'logout' : 'login'}');
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
      _log('Synchronisation terminée: $debugSnapshot');
    } catch (error, stackTrace) {
      _logError('Échec de synchronisation', error, stackTrace);
      _error = 'Impossible de synchroniser votre abonnement. Réessayez plus tard.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await _initialize();
    if (!_configured) {
      _log('Actualisation ignorée: RevenueCat non configuré.');
      return;
    }

    _log('Actualisation RevenueCat demandée.');
    _setLoading(true);
    try {
      _applyCustomerInfo(await Purchases.getCustomerInfo());
      await _loadOffering();
      _error = null;
      _log('Actualisation terminée: $debugSnapshot');
    } catch (error, stackTrace) {
      _logError('Échec d’actualisation', error, stackTrace);
      _error = 'Les offres sont indisponibles pour le moment.';
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerInfo?> purchase(Package package) async {
    await _initialize();
    if (!_configured) {
      _log('Achat ignoré: RevenueCat non configuré.');
      return null;
    }

    _log('Achat demandé: package=${package.identifier}, product=${package.storeProduct.identifier}');
    _setLoading(true);
    try {
      final result = await Purchases.purchasePackage(package);
      _applyCustomerInfo(result.customerInfo);
      _error = null;
      _log('Achat terminé: $debugSnapshot');
      return result.customerInfo;
    } on PlatformException catch (exception) {
      final errorCode = PurchasesErrorHelper.getErrorCode(exception);
      _log('Achat RevenueCat interrompu: code=$errorCode, message=${exception.message ?? 'none'}');
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _error =
            'Le paiement n’a pas abouti. Vérifiez votre connexion puis réessayez.';
      }
      return null;
    } catch (error, stackTrace) {
      _logError('Échec d’achat inattendu', error, stackTrace);
      _error = 'Le paiement n’a pas abouti. Vérifiez votre connexion puis réessayez.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    await _initialize();
    if (!_configured) {
      _log('Restauration ignorée: RevenueCat non configuré.');
      return null;
    }

    _log('Restauration RevenueCat demandée.');
    _setLoading(true);
    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      _error = null;
      _log('Restauration terminée: $debugSnapshot');
      return info;
    } catch (error, stackTrace) {
      _logError('Échec de restauration', error, stackTrace);
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
    final opened = await launchUrl(
      Uri.parse(managementUrl),
      mode: LaunchMode.externalApplication,
    );
    if (opened) {
      _error = null;
      notifyListeners();
    } else {
      _error = 'Impossible d’ouvrir Google Play pour gérer l’abonnement.';
      notifyListeners();
    }
  }

  Future<void> _initialize() async {
    if (_configured || !Platform.isAndroid) return;

    _initialization ??= _initializeOnce();
    await _initialization;
  }

  Future<void> _initializeOnce() async {
    final apiKey = dotenv.env['REVENUECAT_ANDROID_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      _log('Configuration impossible: REVENUECAT_ANDROID_API_KEY absente.');
      _error = 'Les paiements Premium ne sont pas encore configurés.';
      notifyListeners();
      return;
    }

    try {
      _log('Configuration RevenueCat démarrée (environnement=${apiKey.startsWith('test_') ? 'Test Store' : 'store configuré'}).');
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      _configured = true;
      // Do not call refresh() here: refresh() waits for _initialize(), which is
      // currently waiting for this method. Loading the initial state directly
      // avoids leaving the paywall permanently in its loading state.
      _setLoading(true);
      try {
        _applyCustomerInfo(await Purchases.getCustomerInfo());
        await _loadOffering();
        _error = null;
        _log('Configuration RevenueCat terminée: $debugSnapshot');
      } finally {
        _setLoading(false);
      }
    } catch (error, stackTrace) {
      _logError('Échec de configuration RevenueCat', error, stackTrace);
      _error = 'Les paiements Premium ne sont pas disponibles pour le moment.';
      notifyListeners();
    }
  }

  Future<void> _loadOffering() async {
    final offerings = await Purchases.getOfferings();
    _offering = offerings.all[offeringId] ?? offerings.current;
    if (_offering == null) {
      _error = 'Aucune offre Premium n’est disponible actuellement.';
      _log('Aucune offering disponible. offerings=${offerings.all.keys.join(',')}');
    } else {
      final packages = _offering!.availablePackages
          .map((package) => '${package.identifier}:${package.storeProduct.identifier}:${package.storeProduct.priceString}')
          .join(' | ');
      _log('Offering chargée: id=${_offering!.identifier}, packages=[$packages]');
    }
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    _log('CustomerInfo reçu: $debugSnapshot');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[RevenueCat] $message');
  }

  void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[RevenueCat] $context: $error');
      debugPrintStack(stackTrace: stackTrace, label: '[RevenueCat] $context');
    }
  }
}
