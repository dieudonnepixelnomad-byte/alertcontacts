import 'package:flutter/material.dart';
import '../../../core/services/paywall_trigger_service.dart';
import '../../../theme/colors.dart';

class ContactAvatarData {
  final String initial;
  final Color color;
  const ContactAvatarData({required this.initial, required this.color});
}

class PaywallTriggerModal extends StatelessWidget {
  final String trigger;
  final List<ContactAvatarData> avatars;

  const PaywallTriggerModal({
    super.key,
    required this.trigger,
    this.avatars = const [],
  });

  static const _avatarPalette = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFF22C55E),
  ];

  static Color paletteColor(int index) =>
      _avatarPalette[index % _avatarPalette.length];

  static Future<bool?> show(
    BuildContext context, {
    required String trigger,
    List<ContactAvatarData> avatars = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaywallTriggerModal(trigger: trigger, avatars: avatars),
    );
  }

  bool get _isContactTrigger => trigger == 'contact_limit';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _isContactTrigger
                    ? Icons.people_outline
                    : Icons.location_on_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Tu as atteint ta limite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              _isContactTrigger
                  ? 'Le plan gratuit permet jusqu\'à ${PaywallTriggerService.freeContactsLimit} proches connectés. Pour continuer, passe à Family.'
                  : 'Le plan gratuit permet jusqu\'à ${PaywallTriggerService.freeZonesLimit} zones. Pour continuer, passe à Family.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray600,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            if (avatars.isNotEmpty) ...[
              const SizedBox(height: 20),
              _AvatarRow(avatars: avatars),
            ],

            const SizedBox(height: 20),

            // features
            ...[
              'Proches illimités',
              '10 zones (au lieu de 2)',
              'Historique 30 jours',
            ].map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(f, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Essayer Family 14 j gratuit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Pas maintenant',
                style: TextStyle(color: AppColors.gray400, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AvatarRow extends StatelessWidget {
  final List<ContactAvatarData> avatars;
  const _AvatarRow({required this.avatars});

  static const double _size = 36;
  static const double _overlap = 10;

  @override
  Widget build(BuildContext context) {
    final displayed = avatars.take(3).toList();
    final total = displayed.length + 1; // +1 for the plus bubble
    final width = _size + (total - 1) * (_size - _overlap);

    return SizedBox(
      height: _size,
      width: width,
      child: Stack(
        children: [
          ...displayed.asMap().entries.map(
            (e) => Positioned(
              left: e.key * (_size - _overlap),
              child: _Circle(
                color: e.value.color,
                child: Text(
                  e.value.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: displayed.length * (_size - _overlap),
            child: _Circle(
              color: AppColors.gray100,
              child: const Icon(Icons.add, size: 16, color: AppColors.gray600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final Widget child;
  final Color color;
  const _Circle({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
