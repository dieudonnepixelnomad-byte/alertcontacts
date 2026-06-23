import 'package:flutter/material.dart';
import '../../../core/services/analytics_service.dart';
import '../../../theme/colors.dart';
import 'paywall_compare_page.dart';

class PaywallPage extends StatefulWidget {
  final String trigger;

  const PaywallPage({super.key, this.trigger = 'settings'});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().logPaywallDisplayed(trigger: widget.trigger);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) AnalyticsService().logPaywallDismissed();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E6868), Color(0xFF124444)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top_rounded, color: AppColors.orange, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'BIENTÔT',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Headline
                        const Text(
                          'Tout le monde\nprotégé.\nSereinement.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Les abonnements premium arrivent bientôt.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Coming soon banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.construction_rounded, color: AppColors.orange, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Le plan premium est en cours de développement. Il sera disponible très prochainement.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Features
                        _FeatureRow(
                          iconBg: AppColors.orange,
                          icon: Icons.all_inclusive,
                          title: 'Proches illimités',
                          subtitle: 'Grands-parents, cousins, amis',
                        ),
                        const SizedBox(height: 10),
                        _FeatureRow(
                          iconBg: const Color(0xFF22C55E),
                          icon: Icons.location_on_outlined,
                          title: '10 zones (au lieu de 2)',
                          subtitle: 'École, sport, grands-parents...',
                        ),
                        const SizedBox(height: 10),
                        _FeatureRow(
                          iconBg: const Color(0xFF3B82F6),
                          icon: Icons.history,
                          title: 'Historique 30 jours',
                          subtitle: 'Vs 7 jours en Free',
                        ),
                        const SizedBox(height: 10),
                        _FeatureRow(
                          iconBg: AppColors.danger,
                          icon: Icons.notifications_active_outlined,
                          title: 'Alertes prioritaires',
                          subtitle: 'SMS de secours sans connexion',
                        ),
                        const SizedBox(height: 28),

                        // Compare plans link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaywallComparePage(),
                                ),
                              );
                            },
                            child: Text(
                              'Voir la comparaison des plans',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
