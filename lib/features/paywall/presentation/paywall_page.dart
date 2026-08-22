import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../theme/colors.dart';

/// Ouvre le paywall configuré à distance dans RevenueCat.
///
/// RevenueCatUI gère les formules, l'achat et la restauration. Le
/// SubscriptionService reçoit ensuite CustomerInfo et actualise les gates.
class PaywallPage extends StatefulWidget {
  final String trigger;

  const PaywallPage({super.key, this.trigger = 'settings'});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logPaywallDisplayed(trigger: widget.trigger);
    _log('Paywall demandé, trigger=${widget.trigger}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPaywall());
  }

  Future<void> _openPaywall() async {
    if (_opening) return;

    final subscriptions = context.read<SubscriptionService>();
    setState(() {
      _opening = true;
      _error = null;
    });

    try {
      await subscriptions.refresh();
      if (!mounted) return;
      _log('État avant affichage: ${subscriptions.debugSnapshot}');

      if (subscriptions.isPremium) {
        _log('Paywall non affiché: entitlement premium déjà actif.');
        Navigator.of(context).pop();
        return;
      }

      if (!subscriptions.isConfigured) {
        throw StateError(
          subscriptions.error ?? 'Les paiements Premium ne sont pas configurés.',
        );
      }

      final result = await RevenueCatUI.presentPaywall(
        offering: subscriptions.offering,
      );
      _log('Paywall RevenueCat fermé: result=$result');
      await subscriptions.refresh();

      if (!mounted) return;
      if (subscriptions.isPremium) {
        _log('Achat confirmé par entitlement premium: ${subscriptions.debugSnapshot}');
        AnalyticsService().logSubscriptionPurchased(
          tier: 'premium',
          billing: 'revenuecat_paywall',
        );
      }
      if (!subscriptions.isPremium) {
        _log('Aucun entitlement premium après fermeture du paywall.');
      }
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      _log('Erreur pendant le parcours paywall: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace, label: '[Paywall] erreur');
      }
      if (mounted) {
        setState(() {
          _error = subscriptions.error ??
              'Impossible d’ouvrir les offres Premium. Réessayez plus tard.';
        });
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[Paywall] $message');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) AnalyticsService().logPaywallDismissed();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _opening
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Les offres Premium sont indisponibles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _openPaywall,
                          child: const Text('Réessayer'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Fermer',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
