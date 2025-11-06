// lib/features/zones_danger/presentation/widgets/nearby_zones_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/models/danger_zone.dart';
import '../../../../theme/colors.dart';

class NearbyZonesDialog extends StatelessWidget {
  final List<DangerZone> nearbyZones;
  final DangerZone proposedZone;
  final VoidCallback onCreateNew;
  final Function(DangerZone) onConfirmExisting;

  const NearbyZonesDialog({
    super.key,
    required this.nearbyZones,
    required this.proposedZone,
    required this.onCreateNew,
    required this.onConfirmExisting,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.alert,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zones similaires détectées',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nous avons trouvé ${nearbyZones.length} zone(s) de danger similaire(s) à proximité. Voulez-vous confirmer une zone existante ou créer une nouvelle zone ?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des zones proches
            ...nearbyZones.map((zone) => _buildZoneCard(context, zone)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCreateNew();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.alert,
            side: BorderSide(color: AppColors.alert),
          ),
          child: const Text('Créer quand même'),
        ),
      ],
    );
  }

  Widget _buildZoneCard(BuildContext context, DangerZone zone) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: _getSeverityColor(zone.severity),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${zone.confirmations} confirmations',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.safe,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (zone.description != null) ...[
            const SizedBox(height: 8),
            Text(
              zone.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirmExisting(zone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safe,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Confirmer cette zone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return Colors.orange;
      case DangerSeverity.med:
        return AppColors.alert;
      case DangerSeverity.high:
        return Colors.red;
    }
  }
}