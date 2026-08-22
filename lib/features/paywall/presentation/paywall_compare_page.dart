import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

class PaywallComparePage extends StatelessWidget {
  const PaywallComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparer les plans'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PlanCard(
            title: 'Free',
            price: '0 €',
            color: Colors.white,
            features: ['1 proche', '1 zone de sécurité', '24 h d’historique'],
          ),
          SizedBox(height: 12),
          _PlanCard(
            title: 'Premium',
            price: 'Formules et prix affichés par Google Play',
            color: AppColors.primary,
            features: [
              'Proches sans limite',
              'Zones de sécurité sans limite',
              'Historique et alertes étendus',
              'Mode invisible et suivi de trajet',
            ],
          ),
          SizedBox(height: 22),
          Text(
            'Le prix final, la devise et les conditions applicables sont affichés par Google Play avant confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final Color color;
  final List<String> features;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.color,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = color == AppColors.primary;
    final foreground = isPremium ? Colors.white : AppColors.gray900;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isPremium ? null : Border.all(color: AppColors.gray200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
        const SizedBox(height: 15),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.check, color: isPremium ? const Color(0xFF8BE0D1) : AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(feature, style: TextStyle(color: foreground))),
            ]),
          ),
      ]),
    );
  }
}
