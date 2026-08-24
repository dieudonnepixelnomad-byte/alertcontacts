import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/subscription_service.dart';
import '../../../theme/colors.dart';
import '../../paywall/presentation/paywall_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubscriptionService>().refresh();
    });
  }

  Future<void> _openPaywall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaywallPage(trigger: 'settings_subscription'),
      ),
    );
    if (mounted) await context.read<SubscriptionService>().refresh();
  }

  Future<void> _manageSubscription() async {
    final subscriptions = context.read<SubscriptionService>();
    await subscriptions.openManagement();
    if (mounted && subscriptions.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(subscriptions.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: cs.onSurface,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Mon abonnement',
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, subscriptions, _) {
          final isPremium = subscriptions.isPremium;
          final isAdmin = subscriptions.hasAdminAccess;
          final entitlement = subscriptions.customerInfo
              ?.entitlements.active[SubscriptionService.entitlementId];
          final productId = entitlement?.productIdentifier ??
              _firstActiveSubscription(
                subscriptions.customerInfo?.activeSubscriptions,
              );
          final expirationDate = _formatRevenueCatDate(entitlement?.expirationDate);
          final purchaseDate = _formatRevenueCatDate(entitlement?.latestPurchaseDate);
          final hasManagementUrl =
              subscriptions.customerInfo?.managementURL?.isNotEmpty == true;

          return RefreshIndicator(
            onRefresh: subscriptions.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _StatusCard(
                  isPremium: isPremium,
                  isLoading: subscriptions.isLoading,
                ),
                const SizedBox(height: 16),
                _DetailsCard(
                  rows: [
                    _DetailRow(
                      label: 'Offre',
                      value: isAdmin
                          ? 'Accès administrateur'
                          : (isPremium ? _productLabel(productId) : 'Free'),
                    ),
                    _DetailRow(
                      label: 'Statut',
                      value: isAdmin
                          ? 'Exemption administrateur'
                          : (isPremium
                              ? _renewalLabel(entitlement?.willRenew)
                              : 'Aucun abonnement actif'),
                    ),
                    if (purchaseDate != null)
                      _DetailRow(label: 'Dernier achat', value: purchaseDate),
                    if (expirationDate != null)
                      _DetailRow(
                        label: entitlement?.willRenew == false
                            ? 'Acces jusqu\'au'
                            : 'Renouvellement',
                        value: expirationDate,
                      ),
                    if (productId != null)
                      _DetailRow(label: 'Produit', value: productId),
                  ],
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  Text(
                    'Votre compte administrateur a accès aux fonctionnalités Premium sans abonnement.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ] else if (isPremium) ...[
                  FilledButton.icon(
                    onPressed: hasManagementUrl ? _manageSubscription : null,
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('Gerer ou annuler sur Google Play'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'L\'annulation se fait dans Google Play. Si tu annules, '
                    'l\'acces Premium reste actif jusqu\'a la fin de la periode deja payee.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _openPaywall,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Passer a Premium'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: subscriptions.restorePurchases,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Restaurer mes achats'),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: subscriptions.isLoading ? null : subscriptions.refresh,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Actualiser'),
                ),
                if (subscriptions.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    subscriptions.error!,
                    style: tt.bodySmall?.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _productLabel(String? productId) {
    return switch (productId) {
      SubscriptionService.monthlyProductId => 'Premium mensuel',
      SubscriptionService.annualProductId => 'Premium annuel',
      _ => 'Premium',
    };
  }

  String _renewalLabel(bool? willRenew) {
    return switch (willRenew) {
      true => 'Actif, renouvellement automatique',
      false => 'Annule, actif jusqu\'a echeance',
      null => 'Actif',
    };
  }

  String? _firstActiveSubscription(List<String>? productIds) {
    if (productIds == null || productIds.isEmpty) return null;
    return productIds.first;
  }

  String? _formatRevenueCatDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year} à '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isPremium,
    required this.isLoading,
  });

  final bool isPremium;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final color = isPremium ? AppColors.success : AppColors.gray600;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_outlined
                  : Icons.lock_open_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium actif' : 'Plan Free',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPremium
                      ? 'Tes fonctionnalites Premium sont debloquees.'
                      : 'Tu peux passer a Premium depuis cette page.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: List.generate(rows.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(height: 1, color: cs.outlineVariant);
          }
          return rows[index ~/ 2];
        }),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
