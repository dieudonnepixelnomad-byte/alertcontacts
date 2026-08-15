import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PaywallComparePage extends StatelessWidget {
  const PaywallComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparer les plans',
              style: tt.titleSmall?.copyWith(color: AppColors.gray900),
            ),
            Text(
              'Trois niveaux. Tu peux changer à tout moment.',
              style: tt.labelMedium?.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  // Free
                  _FreeTierCard(tt: tt),
                  const SizedBox(height: 10),

                  // Family (recommended)
                  _FamilyTierCard(tt: tt),
                  const SizedBox(height: 10),

                  // Family+
                  _FamilyPlusTierCard(tt: tt),
                  const SizedBox(height: 20),

                  Text(
                    'Annulation en 1 tap. Aucun engagement.',
                    style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Coming soon footer
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Abonnements en cours de développement',
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Free tier card ───────────────────────────────────────────────────────────

class _FreeTierCard extends StatelessWidget {
  final TextTheme tt;
  const _FreeTierCard({required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free',
                style: tt.titleSmall?.copyWith(color: AppColors.gray900),
              ),
              Text(
                '0 €',
                style: tt.titleSmall?.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Actuel',
            style: tt.bodySmall?.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _Chip(label: '2 proches'),
              _Chip(label: '1 zone'),
              _Chip(label: '24 h d\'historique'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Family tier card (recommended) ──────────────────────────────────────────

class _FamilyTierCard extends StatelessWidget {
  final TextTheme tt;
  const _FamilyTierCard({required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family',
                    style: tt.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '14 j gratuits',
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '4,99 €',
                    style: tt.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/mois',
                      style: tt.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // RECOMMANDÉ badge
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'RECOMMANDÉ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),

          const SizedBox(height: 12),
          ...[
            'Proches illimités',
            '10 zones',
            '30 j d\'historique',
            'Alertes prioritaires',
          ].map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: tt.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Family+ tier card ────────────────────────────────────────────────────────

class _FamilyPlusTierCard extends StatelessWidget {
  final TextTheme tt;
  const _FamilyPlusTierCard({required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family+',
                    style: tt.titleSmall?.copyWith(color: AppColors.gray900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pour familles élargies',
                    style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '9,99 €',
                    style: tt.titleMedium?.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/mois',
                      style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'Tout Family',
            'Zones illimitées',
            'Historique 12 mois',
            'Bouton SOS dédié',
            'Support prioritaire',
          ].map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: tt.bodySmall?.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gray600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
