import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../theme/colors.dart';
import 'paywall_compare_page.dart';

class PaywallPage extends StatefulWidget {
  final String trigger;
  const PaywallPage({super.key, this.trigger = 'settings'});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  String? _selectedProductId = SubscriptionService.annualProductId;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logPaywallDisplayed(trigger: widget.trigger);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().refresh();
    });
  }

  Future<void> _purchase(SubscriptionService subscriptions, Package package) async {
    final wasPremium = subscriptions.isPremium;
    final info = await subscriptions.purchase(package);
    if (!mounted || info == null) return;
    if (subscriptions.isPremium && !wasPremium) {
      final isTrial = info.entitlements.active[SubscriptionService.entitlementId]
              ?.periodType == PeriodType.trial;
      if (isTrial) {
        AnalyticsService().logSubscriptionTrialStarted(tier: 'premium', billing: package.storeProduct.identifier);
      } else {
        AnalyticsService().logSubscriptionPurchased(tier: 'premium', billing: package.storeProduct.identifier);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium est maintenant actif.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<SubscriptionService>();
    final monthly = _packageFor(subscriptions, SubscriptionService.monthlyProductId);
    final annual = _packageFor(subscriptions, SubscriptionService.annualProductId);
    final selected = _selectedProductId == SubscriptionService.monthlyProductId ? monthly : annual;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) { if (didPop) AnalyticsService().logPaywallDismissed(); },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(child: Column(children: [
          _Header(onClose: () => Navigator.pop(context)),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: subscriptions.isPremium
                ? _ActiveSubscription(subscriptions: subscriptions)
                : _PurchaseContent(
                    subscriptions: subscriptions, monthly: monthly, annual: annual,
                    selectedProductId: _selectedProductId,
                    onSelect: (id) => setState(() => _selectedProductId = id),
                    onPurchase: selected == null ? null : () => _purchase(subscriptions, selected),
                  ),
          )),
          _Footer(subscriptions: subscriptions, onPurchase: selected == null ? null : () => _purchase(subscriptions, selected)),
        ])),
      ),
    );
  }

  Package? _packageFor(SubscriptionService service, String productId) {
    for (final package in service.offering?.availablePackages ?? const <Package>[]) {
      if (package.storeProduct.identifier == productId) return package;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: onClose),
      const Spacer(),
      const Text('ALERTCONTACTS PREMIUM', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .5)),
    ]),
  );
}

class _PurchaseContent extends StatelessWidget {
  final SubscriptionService subscriptions;
  final Package? monthly;
  final Package? annual;
  final String? selectedProductId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onPurchase;
  const _PurchaseContent({required this.subscriptions, required this.monthly, required this.annual, required this.selectedProductId, required this.onSelect, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isLoading && subscriptions.offering == null) {
      return const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Protégez toute votre tribu.', style: TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w700, height: 1.15)),
      const SizedBox(height: 10),
      Text('Premium débloque toutes les fonctionnalités de protection, sans limite.', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 14)),
      const SizedBox(height: 24),
      const _Benefits(),
      const SizedBox(height: 24),
      if (monthly != null) _PlanOption(package: monthly!, selected: selectedProductId == SubscriptionService.monthlyProductId, title: 'Mensuel', subtitle: '14 jours gratuits, puis renouvellement mensuel', onTap: () => onSelect(SubscriptionService.monthlyProductId)),
      if (monthly != null && annual != null) const SizedBox(height: 10),
      if (annual != null) _PlanOption(package: annual!, selected: selectedProductId != SubscriptionService.monthlyProductId, title: 'Annuel', subtitle: '14 jours gratuits, puis renouvellement annuel', badge: 'MEILLEURE VALEUR', onTap: () => onSelect(SubscriptionService.annualProductId)),
      if (monthly == null && annual == null) _Unavailable(message: subscriptions.error),
      if (subscriptions.error != null && (monthly != null || annual != null)) Padding(padding: const EdgeInsets.only(top: 12), child: _Unavailable(message: subscriptions.error)),
      const SizedBox(height: 18),
      Center(child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallComparePage())),
        child: const Text('Voir le détail des fonctionnalités', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
      )),
    ]);
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();
  @override
  Widget build(BuildContext context) => const Column(children: [
    _Benefit(icon: Icons.people_alt_outlined, text: 'Proches sans limite'),
    _Benefit(icon: Icons.location_on_outlined, text: 'Zones de sécurité sans limite'),
    _Benefit(icon: Icons.history, text: 'Historique et alertes étendus'),
    _Benefit(icon: Icons.visibility_off_outlined, text: 'Mode invisible et suivi de trajet'),
  ]);
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      const Icon(Icons.check_circle, color: Color(0xFF8BE0D1), size: 20), const SizedBox(width: 10),
      Icon(icon, color: Colors.white70, size: 19), const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]),
  );
}

class _PlanOption extends StatelessWidget {
  final Package package;
  final bool selected;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _PlanOption({required this.package, required this.selected, required this.title, required this.subtitle, required this.onTap, this.badge});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: selected ? Colors.white : Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.orange : Colors.white38, width: selected ? 2 : 1)),
      child: Row(children: [
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.orange : Colors.white70), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: TextStyle(color: selected ? AppColors.gray900 : Colors.white, fontWeight: FontWeight.w700)),
            if (badge != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(8)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)))],
          ]), const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: selected ? AppColors.gray600 : Colors.white70, fontSize: 12)),
        ])),
        Text(package.storeProduct.priceString, style: TextStyle(color: selected ? AppColors.gray900 : Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ]),
    ),
  );
}

class _ActiveSubscription extends StatelessWidget {
  final SubscriptionService subscriptions;
  const _ActiveSubscription({required this.subscriptions});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.verified_rounded, color: Color(0xFF8BE0D1), size: 48), const SizedBox(height: 16),
    const Text('Premium est actif.', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
    Text('Votre protection Premium est bien activée sur ce compte.', style: TextStyle(color: Colors.white.withValues(alpha: .8))), const SizedBox(height: 28),
    OutlinedButton.icon(onPressed: subscriptions.isLoading ? null : subscriptions.openManagement, icon: const Icon(Icons.open_in_new), label: const Text('Gérer dans Google Play'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54))),
  ]);
}

class _Footer extends StatelessWidget {
  final SubscriptionService subscriptions;
  final VoidCallback? onPurchase;
  const _Footer({required this.subscriptions, required this.onPurchase});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(24, 12, 24, 14 + MediaQuery.of(context).padding.bottom), color: AppColors.primary,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (!subscriptions.isPremium) SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: subscriptions.isLoading ? null : onPurchase,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
        child: subscriptions.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Essayer Premium gratuitement', style: TextStyle(fontWeight: FontWeight.w700)),
      )),
      TextButton(onPressed: subscriptions.isLoading ? null : subscriptions.restorePurchases, child: const Text('Restaurer mes achats', style: TextStyle(color: Colors.white70))),
      const Text('Essai gratuit de 14 jours. Puis renouvellement automatique au prix affiché par Google Play, sauf annulation avant la fin de l’essai.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 10, height: 1.35)),
    ]),
  );
}

class _Unavailable extends StatelessWidget {
  final String? message;
  const _Unavailable({this.message});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text(message ?? 'Les offres Premium sont indisponibles actuellement.', style: const TextStyle(color: Colors.white)));
}
