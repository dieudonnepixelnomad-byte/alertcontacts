import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/my_community_report.dart';
import '../../../core/services/global_navigation_service.dart';
import '../../../theme/colors.dart';
import '../providers/incident_provider.dart';

/// Historique privé des signalements créés par l'utilisateur.
class MyCommunityAlertsPage extends StatefulWidget {
  const MyCommunityAlertsPage({super.key});

  @override
  State<MyCommunityAlertsPage> createState() => _MyCommunityAlertsPageState();
}

class _MyCommunityAlertsPageState extends State<MyCommunityAlertsPage> {
  final Set<int> _deletingReportIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<IncidentProvider>().loadMyReports(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes alertes')),
      body: Consumer<IncidentProvider>(
        builder: (_, provider, __) {
          if (provider.isLoadingMyReports && provider.myReports.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.myReports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: provider.loadMyReports,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.myReports.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadMyReports,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.campaign_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('Tu n’as encore créé aucune alerte.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadMyReports,
            child: MyCommunityAlertsList(
              reports: provider.myReports,
              deletingReportIds: _deletingReportIds,
              onLocate: _showOnMap,
              onDelete: _deleteReport,
            ),
          );
        },
      ),
    );
  }

  void _showOnMap(MyCommunityReport report) {
    final incident = report.incident;
    if (incident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La position de cette alerte n’est plus disponible.')),
      );
      return;
    }

    Navigator.of(context).pop();
    GlobalNavigationService.navigateToMapLocation(
      lat: incident.lat,
      lng: incident.lng,
    );
  }

  Future<void> _deleteReport(MyCommunityReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce signalement ?'),
        content: const Text(
          'Ton signalement sera retiré. Si d’autres personnes ont signalé '
          'le même incident, leur alerte restera visible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingReportIds.add(report.id));
    final deleted = await context.read<IncidentProvider>().deleteMyReport(report.id);
    if (!mounted) return;

    setState(() => _deletingReportIds.remove(report.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Signalement supprimé.'
              : 'Impossible de supprimer ce signalement pour le moment.',
        ),
      ),
    );
  }
}

class MyCommunityAlertsList extends StatelessWidget {
  const MyCommunityAlertsList({
    super.key,
    required this.reports,
    this.deletingReportIds = const {},
    this.onLocate,
    this.onDelete,
  });

  final List<MyCommunityReport> reports;
  final Set<int> deletingReportIds;
  final ValueChanged<MyCommunityReport>? onLocate;
  final ValueChanged<MyCommunityReport>? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final report = reports[index];
        return _MyReportCard(
          report: report,
          isDeleting: deletingReportIds.contains(report.id),
          onLocate: onLocate == null ? null : () => onLocate!(report),
          onDelete: onDelete == null ? null : () => onDelete!(report),
        );
      },
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({
    required this.report,
    required this.isDeleting,
    this.onLocate,
    this.onDelete,
  });

  final MyCommunityReport report;
  final bool isDeleting;
  final VoidCallback? onLocate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final incident = report.incident;
    final status = incident?.status;
    final expiredByTimeout = incident?.expiredByTimeout == true ||
        (incident?.status.isLive == true && incident?.isExpired == true);
    final statusLabel = expiredByTimeout ? 'Expirée' : switch (status?.value) {
      'resolved' => 'Résolue',
      'expired' => 'Expirée',
      'rejected' => 'Rejetée',
      _ => 'Active',
    };
    final statusColor = statusLabel == 'Active' ? AppColors.success : Colors.grey;
    final age = DateTime.now().difference(report.createdAt);
    final timeLabel = age.inMinutes < 60
        ? 'il y a ${age.inMinutes} min'
        : age.inHours < 24
            ? 'il y a ${age.inHours} h'
            : 'il y a ${age.inDays} j';

    return Semantics(
      label: 'Alerte créée : ${report.type.label}, $statusLabel',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${report.type.label} signalé',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(statusLabel, style: TextStyle(color: statusColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$timeLabel · ${report.severity.label}'),
                    if (expiredByTimeout && incident?.expiresAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Cette alerte a expiré le '
                        '${DateFormat('d MMM à HH:mm', 'fr').format(incident!.expiresAt!.toLocal())}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                    if (report.comment != null && report.comment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(report.comment!),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          key: Key('show_my_alert_${report.id}_on_map'),
                          onPressed: incident == null ? null : onLocate,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Voir sur la carte'),
                        ),
                        const Spacer(),
                        IconButton(
                          key: Key('delete_my_alert_${report.id}'),
                          tooltip: 'Supprimer le signalement',
                          onPressed: isDeleting ? null : onDelete,
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
