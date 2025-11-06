import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../core/models/danger_zone.dart';
import '../../../theme/colors.dart';
import '../../../router/app_router.dart';
import '../providers/danger_zone_notifier.dart';
import '../providers/ignored_danger_zones_provider.dart';
import 'widgets/confirm_danger_dialog.dart';
import 'widgets/report_abuse_dialog.dart';
import 'widgets/ignore_zone_dialog.dart';

class DangerDetailPage extends StatefulWidget {
  final String zoneId;

  const DangerDetailPage({
    super.key,
    required this.zoneId,
  });

  @override
  State<DangerDetailPage> createState() => _DangerDetailPageState();
}

class _DangerDetailPageState extends State<DangerDetailPage> {
  DangerZone? _zone;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadZoneDetails();
  }

  Future<void> _loadZoneDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifier = context.read<DangerZoneNotifier>();
      await notifier.loadDangerZoneDetails(widget.zoneId);
      
      setState(() {
        _zone = notifier.state.selectedZone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des détails';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la zone'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.appShell);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _zone != null
                  ? _buildZoneDetails()
                  : _buildNotFoundView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.alert,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadZoneDetails,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Zone non trouvée',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDetails() {
    final zone = _zone!;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte miniature
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withOpacity(0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(zone.center.lat, zone.center.lng),
                zoom: 16,
              ),
              circles: {
                gmaps.Circle(
                  circleId: const gmaps.CircleId('danger_zone'),
                  center: gmaps.LatLng(zone.center.lat, zone.center.lng),
                  radius: zone.radiusMeters,
                  fillColor: _getSeverityColor(zone.severity).withOpacity(0.2),
                  strokeColor: _getSeverityColor(zone.severity),
                  strokeWidth: 2,
                ),
              },
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('danger_center'),
                  position: gmaps.LatLng(zone.center.lat, zone.center.lng),
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    _getSeverityHue(zone.severity),
                  ),
                ),
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
          ),

          const SizedBox(height: 24),

          // Titre et gravité
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  zone.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildSeverityChip(zone.severity),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          if (zone.description != null && zone.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              zone.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],

          // Informations
          _buildInfoSection(zone),

          const SizedBox(height: 32),

          // Actions
          _buildActionButtons(zone),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(DangerSeverity severity) {
    final color = _getSeverityColor(severity);
    final text = _getSeverityText(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoSection(DangerZone zone) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.radio_button_checked,
              'Rayon',
              '${zone.radiusMeters.toInt()} mètres',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.verified,
              'Confirmations',
              '${zone.confirmations} confirmation${zone.confirmations > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Signalé',
              _formatDate(zone.lastReportAt),
            ),
            if (zone.createdAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Créé',
                _formatDate(zone.createdAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DangerZone zone) {
    return Consumer<DangerZoneNotifier>(
      builder: (context, notifier, child) {
        final isConfirming = notifier.state.status == DangerZoneStatus.confirming;
        final isReporting = notifier.state.status == DangerZoneStatus.reporting;

        return Column(
          children: [
            // Confirmer le danger
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConfirming ? null : () => _confirmDanger(zone.id),
                icon: isConfirming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.thumb_up),
                label: Text(isConfirming ? 'Confirmation...' : 'Confirmer ce danger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Signaler un abus
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isReporting ? null : () => _reportAbuse(zone.id),
                icon: isReporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag),
                label: Text(isReporting ? 'Signalement...' : 'Signaler un abus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.alert,
                  side: BorderSide(color: AppColors.alert),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ignorer cette zone
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _ignoreZone(zone),
                icon: const Icon(Icons.visibility_off),
                label: const Text('Ignorer cette zone'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDanger(String zoneId) async {
    final zone = _zone;
    if (zone == null) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmDangerDialog(
        zone: zone,
        onConfirm: () async {
          // Utiliser Future.microtask pour éviter setState pendant build
          Future.microtask(() async {
            final notifier = context.read<DangerZoneNotifier>();
            await notifier.confirmDangerZone(zoneId);
            // Recharger les détails après confirmation
            await _loadZoneDetails();
          });
        },
      ),
    );
  }

  Future<void> _reportAbuse(String zoneId) async {
    final zone = _zone;
    if (zone == null) return;

    showDialog(
      context: context,
      builder: (context) => ReportAbuseDialog(
        zoneId: zoneId,
        zoneTitle: zone.title,
        onReport: (reason) async {
          // Utiliser Future.microtask pour éviter setState pendant build
          Future.microtask(() async {
            final notifier = context.read<DangerZoneNotifier>();
            await notifier.reportDangerZoneAbuse(zoneId, reason);
          });
        },
      ),
    );
  }

  Future<void> _ignoreZone(DangerZone zone) async {
    showDialog(
      context: context,
      builder: (context) => IgnoreZoneDialog(
        zone: zone,
        onIgnore: (durationHours) async {
          final provider = context.read<IgnoredDangerZonesProvider>();
          final reason = durationHours == null 
              ? 'Ignoré définitivement' 
              : 'Ignoré pour ${durationHours}h';
          await provider.ignoreDangerZone(
            dangerZoneId: int.parse(zone.id),
            reason: reason,
          );
        },
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

  double _getSeverityHue(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return gmaps.BitmapDescriptor.hueOrange;
      case DangerSeverity.med:
        return 5; // rouge clair
      case DangerSeverity.high:
        return gmaps.BitmapDescriptor.hueRed;
    }
  }

  String _getSeverityText(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'FAIBLE';
      case DangerSeverity.med:
        return 'MOYEN';
      case DangerSeverity.high:
        return 'ÉLEVÉ';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}