import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class AlertDetailPage extends StatelessWidget {
  final Map<String, dynamic> alert;

  const AlertDetailPage({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gravity = alert['gravity'] as String? ?? 'low';
    final gravityColor = _gravityColor(gravity);
    final gravityLabel = _gravityLabel(gravity);
    final type = alert['type'] as String? ?? 'other';
    final description = alert['description'] as String?;
    final confirmations = alert['confirmations'] as int? ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
          color: AppColors.gray900,
        ),
        title: Text('Détail de l\'alerte', style: tt.titleSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gravity badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: gravityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gravityColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: gravityColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gravityLabel,
                        style: tt.bodySmall?.copyWith(
                          color: gravityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_typeLabel(type), style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Signalé il y a quelques minutes',
              style: tt.labelMedium?.copyWith(color: AppColors.gray400),
            ),
            if (description != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(description, style: tt.bodyMedium),
              ),
            ],
            const SizedBox(height: 20),

            // Confirmations bar
            Text(
              'Confirmations',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (confirmations / 10).clamp(0.0, 1.0),
                      backgroundColor: AppColors.gray200,
                      color: gravityColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$confirmations',
                  style: tt.bodyMedium?.copyWith(
                    color: gravityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'confirm'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Je confirme'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'deny'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Pas vu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray400,
                      side: const BorderSide(color: AppColors.gray200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, 'report'),
                child: Text(
                  'Signaler comme abusif',
                  style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _gravityColor(String gravity) => switch (gravity) {
    'high'   => AppColors.gravityHigh,
    'medium' => AppColors.gravityMid,
    _        => AppColors.gravityLow,
  };

  String _gravityLabel(String gravity) => switch (gravity) {
    'high'   => 'Élevé',
    'medium' => 'Moyen',
    _        => 'Faible',
  };

  String _typeLabel(String type) => switch (type) {
    'accident'           => 'Accident',
    'suspect'            => 'Personne suspecte',
    'fire'               => 'Incendie',
    'aggression'         => 'Agression',
    'suspicious_package' => 'Colis suspect',
    _                    => 'Incident signalé',
  };
}
