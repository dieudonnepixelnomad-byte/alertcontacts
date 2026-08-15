import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';

/// Bandeau « trajet en cours » affiché sur la carte d'accueil tant qu'un
/// trajet démarré (§5.4 étape 6) n'a pas été terminé ou arrêté.
class ActiveRouteBanner extends StatelessWidget {
  const ActiveRouteBanner({
    super.key,
    this.destinationLabel,
    required this.onStop,
  });

  final String? destinationLabel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final label = destinationLabel != null && destinationLabel!.isNotEmpty
        ? 'Trajet en cours · $destinationLabel'
        : 'Trajet en cours';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onStop,
            child: Text(
              'Arrêter',
              style: tt.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
