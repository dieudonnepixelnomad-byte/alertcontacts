import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/incident.dart';
import '../../../core/services/analytics_service.dart';
import '../../../theme/colors.dart';
import '../providers/incident_provider.dart';

/// Fiche incident — CDC V4.1 §6.5
///
/// Ajouts par rapport au V4.0 :
///   * « Signalé par N personnes » remplace le compteur de confirmations seul —
///     nuance entre témoignage et vérification (§6.7) ;
///   * bouton « C'est terminé » (§4.7a), symétrique de la confirmation, qui
///     donne enfin une fin de vie à un incident résolu avant son TTL ;
///   * indicateur de fiabilité discret ;
///   * mention explicite quand l'incident n'affecte pas les itinéraires — la
///     transparence du §4.11 vaut mieux qu'un silence.
class IncidentDetailSheet extends StatelessWidget {
  const IncidentDetailSheet({super.key, required this.incident});

  final Incident incident;

  static Future<void> show(BuildContext context, Incident incident) {
    AnalyticsService().logCommunityAlertViewed(gravity: incident.severity.value);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IncidentDetailSheet(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // On suit l'incident dans le provider : confirmer ou résoudre met la
    // fiche à jour sans la rouvrir.
    final live = context.watch<IncidentProvider>().byId(incident.id) ?? incident;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(live.type.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(live.type.label, style: tt.titleSmall),
                      Text(
                        // §6.7 — « signalé », jamais « danger »
                        'Alerte signalée · ${live.severity.label.toLowerCase()}',
                        style: tt.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _ReliabilityChip(incident: live),
              ],
            ),
            const SizedBox(height: 16),
            // Compteur de signalements — remplace le compteur de confirmations
            _InfoRow(
              icon: Icons.groups_outlined,
              label: live.reportCountLabel,
            ),
            if (live.confirmCount > 0)
              _InfoRow(
                icon: Icons.visibility_outlined,
                label: '${live.confirmCount} personne(s) l\'ont revue sur place',
              ),
            if (live.expiresAt != null)
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Active encore ${_remaining(live.expiresAt!)}',
              ),
            if (!live.affectsRouting)
              // §4.11 — l'information reste visible, l'utilisateur décide.
              // L'algorithme ne prend jamais cette décision à sa place.
              _InfoRow(
                icon: Icons.alt_route_outlined,
                label: 'Cette alerte n\'affecte pas le calcul d\'itinéraire',
              ),
            const SizedBox(height: 20),
            // §11.3 — actions décisionnelles en zone basse
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _confirm(context, live),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Je le vois aussi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  // §11.2 — style secondaire, jamais destructif visuellement :
                  // résoudre un incident est un acte utile, pas une suppression.
                  child: OutlinedButton.icon(
                    onPressed: () => _clear(context, live),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('C\'est terminé'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _reportAbuse(context, live),
                child: Text(
                  'Signaler un abus',
                  style: tt.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, Incident incident) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await context.read<IncidentProvider>().confirm(incident.id);

    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Action impossible pour le moment.')),
      );
      return;
    }

    AnalyticsService().logCommunityAlertConfirmed();
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Merci — ton témoignage renforce cette alerte.')),
    );
  }

  Future<void> _clear(BuildContext context, Incident incident) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await context.read<IncidentProvider>().clear(incident.id);

    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Action impossible pour le moment.')),
      );
      return;
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(
        result.status.isLive
            ? 'Merci — on retire cette alerte si d\'autres le confirment.'
            : 'Voie dégagée — l\'alerte est retirée de la carte.',
      ),
    ));
  }

  Future<void> _reportAbuse(BuildContext context, Incident incident) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await context.read<IncidentProvider>().reportAbuse(incident.id);

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Signalement transmis. Merci.' : 'Action impossible pour le moment.'),
    ));
  }

  static String _remaining(DateTime expiresAt) {
    final left = expiresAt.difference(DateTime.now());

    if (left.isNegative) return 'quelques instants';
    if (left.inMinutes < 60) return '${left.inMinutes} min';

    return '${left.inHours} h';
  }
}

/// Indicateur de fiabilité — discret (§6.5).
/// 1 signalement → « non confirmé ». 3+ → « confirmé ».
class _ReliabilityChip extends StatelessWidget {
  const _ReliabilityChip({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final confirmed = incident.isConfirmed;
    final color = confirmed ? AppColors.success : AppColors.gray400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        incident.reliabilityLabel,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
