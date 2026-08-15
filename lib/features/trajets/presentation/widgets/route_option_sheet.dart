import 'package:flutter/material.dart';

import '../../../../core/models/route_plan.dart';
import '../../../../theme/colors.dart';

/// Bottom sheet de sélection d'itinéraire — CDC V4.1 §6.4
///
/// Tri imposé : l'itinéraire sûr en premier, même s'il est plus long. Le
/// serveur trie déjà dans cet ordre ; on ne le réordonne pas côté client.
class RouteOptionSheet extends StatelessWidget {
  const RouteOptionSheet({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.message,
  });

  final List<RouteOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Message serveur — UC-08 notamment : « Aucun itinéraire ne contourne
  /// cette zone. Voici le trajet le plus court — reste vigilant. »
  final String? message;

  static Future<void> show(
    BuildContext context, {
    required List<RouteOption> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    String? message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RouteOptionSheet(
        options: options,
        selectedIndex: selectedIndex,
        onSelect: onSelect,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle 32×3 dp centré — design system
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choisis ton itinéraire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            ...options.map((option) => _OptionCard(
                  option: option,
                  selected: option.index == selectedIndex,
                  onTap: () {
                    onSelect(option.index);
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RouteOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          // §11.2 — carte d'itinéraire 72 dp
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? AppColors.primary.withValues(alpha: 0.06) : null,
          ),
          child: Row(
            children: [
              _SafetyBadge(safety: option.safety),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.safety.label,
                      style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                    ),
                    if (option.detourExcessive) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Détour important',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(option.durationS),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  if (option.deltaS != 0)
                    Text(
                      _formatDelta(option.deltaS),
                      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();

    if (minutes < 60) return '$minutes min';

    return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
  }

  static String _formatDelta(int seconds) {
    final minutes = (seconds / 60).round();

    if (minutes == 0) return '';

    return minutes > 0 ? '+$minutes min' : '$minutes min';
  }
}

/// Pastille 24 dp — ✅ vert · ⚠️ orange · 🔴 rouge (§11.2)
class _SafetyBadge extends StatelessWidget {
  const _SafetyBadge({required this.safety});

  final RouteSafety safety;

  @override
  Widget build(BuildContext context) {
    final color = switch (safety) {
      RouteSafety.avoids => AppColors.success,
      RouteSafety.partial => AppColors.gravityMid,
      RouteSafety.crosses => AppColors.gravityHigh,
    };

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(safety.emoji, style: const TextStyle(fontSize: 12)),
    );
  }
}
