import 'package:flutter/material.dart';
import '../../../../core/models/danger_zone.dart';
import '../../../../core/models/safe_zone.dart'; // Pour LatLng
import '../../../../core/enums/danger_type.dart';
import '../../../../theme/colors.dart';

class DangerZoneDetailsStep extends StatelessWidget {
  final String title;
  final String description;
  final LatLng center;
  final double radius;
  final DangerSeverity severity;
  final DangerType dangerType;

  const DangerZoneDetailsStep({
    super.key,
    required this.title,
    required this.description,
    required this.center,
    required this.radius,
    required this.severity,
    required this.dangerType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          Text(
            'Vérification du signalement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez les informations avant de signaler le danger',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Carte de résumé
          _buildSummaryCard(context),
          const SizedBox(height: 24),

          // Informations détaillées
          _buildDetailsList(context),
          const SizedBox(height: 24),

          // Avertissement
          _buildWarningCard(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.alert.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.alert.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSeverityIcon(severity),
                  color: _getSeverityColor(severity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSeverityLabel(severity),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de la zone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          context,
          icon: Icons.location_on_outlined,
          title: 'Position',
          value: '${center.lat.toStringAsFixed(6)}, ${center.lng.toStringAsFixed(6)}',
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          icon: Icons.warning_outlined,
          title: 'Type de danger',
          value: '${dangerType.emoji} ${dangerType.label}',
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          icon: Icons.radio_button_unchecked,
          title: 'Rayon d\'alerte',
          value: '${radius.round()} mètres',
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          context,
          icon: Icons.schedule_outlined,
          title: 'Signalement',
          value: 'Maintenant',
        ),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: cs.onSurface.withOpacity(0.6),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signalement responsable',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assurez-vous que les informations sont exactes. Les faux signalements peuvent être sanctionnés.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return AppColors.dangerLow;
      case DangerSeverity.med:
        return AppColors.dangerMed;
      case DangerSeverity.high:
        return AppColors.dangerHigh;
    }
  }

  IconData _getSeverityIcon(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return Icons.info_outline;
      case DangerSeverity.med:
        return Icons.warning_amber_outlined;
      case DangerSeverity.high:
        return Icons.dangerous_outlined;
    }
  }

  String _getSeverityLabel(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'Danger faible';
      case DangerSeverity.med:
        return 'Danger modéré';
      case DangerSeverity.high:
        return 'Danger élevé';
    }
  }
}