import 'package:flutter/material.dart';
import '../../../core/models/zone.dart';
import '../../../theme/colors.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDetails;

  const ZoneCard({
    super.key,
    required this.zone,
    this.onTap,
    this.onDelete,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = zone.type == ZoneType.danger;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDanger ? AppColors.alert.withOpacity(0.3) : AppColors.safe.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDanger 
                        ? AppColors.alert.withOpacity(0.1)
                        : AppColors.safe.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDanger ? Icons.warning : Icons.shield,
                      color: isDanger ? AppColors.alert : AppColors.safe,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDanger ? 'Zone de danger' : 'Zone de sécurité',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDanger ? AppColors.alert : AppColors.safe,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          onDetails?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Détails'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description si disponible
              if (zone.description?.isNotEmpty == true) ...[
                Text(
                  zone.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Informations supplémentaires
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${zone.center.lat.toStringAsFixed(4)}, ${zone.center.lng.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${zone.radiusMeters.toInt()}m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              // Gravité pour les zones de danger
              if (isDanger && zone.severity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      size: 16,
                      color: _getSeverityColor(zone.severity!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSeverityLabel(zone.severity!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getSeverityColor(zone.severity!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return AppColors.dangerLow;
      case DangerSeverity.medium:
        return AppColors.dangerMed;
      case DangerSeverity.high:
        return AppColors.dangerHigh;
      case DangerSeverity.critical:
        return AppColors.dangerHigh;
    }
  }

  String _getSeverityLabel(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'Faible';
      case DangerSeverity.medium:
        return 'Modéré';
      case DangerSeverity.high:
        return 'Élevé';
      case DangerSeverity.critical:
        return 'Critique';
    }
  }
}