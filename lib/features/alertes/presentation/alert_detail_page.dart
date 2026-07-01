import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../core/models/danger_zone.dart';
import '../../../theme/colors.dart';
import '../providers/alert_provider.dart';
import '../../zones_danger/providers/danger_zone_notifier.dart';
import '../../zones_danger/providers/ignored_danger_zones_provider.dart';
import '../../zones_danger/presentation/widgets/ignore_zone_dialog.dart';
import '../../zones_danger/presentation/widgets/report_abuse_dialog.dart';

/// Page unifiée pour community alerts (depuis AlertesPage) et danger zones (depuis la carte).
///
/// - `alert` fourni → mode community alert (AlertProvider)
/// - `zoneId` fourni → mode danger zone (DangerZoneNotifier, charge depuis réseau)
class AlertDetailPage extends StatefulWidget {
  final Map<String, dynamic>? alert;
  final String? zoneId;

  const AlertDetailPage({
    super.key,
    this.alert,
    this.zoneId,
  }) : assert(alert != null || zoneId != null);

  @override
  State<AlertDetailPage> createState() => _AlertDetailPageState();
}

class _AlertDetailPageState extends State<AlertDetailPage> {
  bool _isDangerZone = false;
  bool _isLoading = false;
  String? _loadError;

  Map<String, dynamic>? _data;
  DangerZone? _dangerZone;

  bool _acknowledged = false;
  String? _vote;
  bool _voting = false;
  int _localConfirmations = 0;

  @override
  void initState() {
    super.initState();
    if (widget.alert != null) {
      _data = widget.alert;
      _localConfirmations = widget.alert!['confirmations'] as int? ?? 0;
      final id = widget.alert!['id'] as String?;
      if (id != null) {
        _acknowledged = context.read<AlertProvider>().isAcknowledged(id);
      }
    } else {
      _isDangerZone = true;
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadZone());
    }
  }

  Future<void> _loadZone() async {
    try {
      final notifier = context.read<DangerZoneNotifier>();
      await notifier.loadDangerZoneDetails(widget.zoneId!);
      final zone = notifier.state.selectedZone;
      if (!mounted) return;
      if (zone != null) {
        setState(() {
          _dangerZone = zone;
          _data = _zoneToMap(zone);
          _localConfirmations = zone.confirmations;
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _loadError = 'Zone introuvable'; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _loadError = 'Erreur lors du chargement'; });
    }
  }

  Map<String, dynamic> _zoneToMap(DangerZone zone) => {
    'id': zone.id,
    'title': zone.title,
    'gravity': switch (zone.severity) {
      DangerSeverity.high => 'high',
      DangerSeverity.med  => 'medium',
      _                   => 'low',
    },
    'type_label': zone.dangerType.displayName,
    'confirmations': zone.confirmations,
    'description': zone.description,
    'lat': zone.center.lat,
    'lng': zone.center.lng,
    'radius': zone.radiusMeters,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _appBar(tt),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _appBar(tt),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_loadError!, style: tt.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _isLoading = true; _loadError = null; });
                  _loadZone();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final gravity = data['gravity'] as String? ?? 'low';
    final gravityColor = _gravityColor(gravity);
    final displayTitle = (data['type_label'] as String?) ??
        _typeLabel(data['type'] as String? ?? 'other');
    final description = data['description'] as String?;
    final alertId = data['id'] as String?;
    final lat = data['lat'] as double?;
    final lng = data['lng'] as double?;
    final radius = data['radius'] as double?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(tt),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini-carte — seulement pour les zones danger
            if (_isDangerZone && lat != null && lng != null) ...[
              _MiniMap(lat: lat, lng: lng, radius: radius ?? 200, color: gravityColor),
              const SizedBox(height: 20),
            ],

            // Badge gravité
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
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: gravityColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _gravityLabel(gravity),
                    style: tt.bodySmall?.copyWith(color: gravityColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(displayTitle, style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Signalé il y a quelques minutes',
              style: tt.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),

            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(description, style: tt.bodyMedium),
              ),
            ],
            const SizedBox(height: 20),

            // Barre de confirmations
            Row(
              children: [
                Text('Confirmations', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  '$_localConfirmations',
                  style: tt.bodyMedium?.copyWith(color: gravityColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_localConfirmations / 10).clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                color: gravityColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),

            // Vote
            if (_vote != null)
              _VoteChip(vote: _vote!)
            else if (_isDangerZone)
              // Zones danger : seulement "Je confirme" (pas de "Pas vu")
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _voting || alertId == null ? null : () => _castVote(alertId, 'confirm'),
                  icon: _voting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Je confirme ce danger'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _voting || alertId == null ? null : () => _castVote(alertId, 'confirm'),
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
                      onPressed: _voting || alertId == null ? null : () => _castVote(alertId, 'deny'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Pas vu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                onPressed: alertId == null ? null : () => _reportAbuse(alertId),
                child: Text(
                  'Signaler comme abusif',
                  style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action principale bas de page
            if (_isDangerZone && _dangerZone != null)
              _buildIgnoreButton(tt)
            else if (!_isDangerZone)
              _buildAcknowledgeButton(tt, alertId),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(TextTheme tt) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
      color: Theme.of(context).colorScheme.onSurface,
    ),
    title: Text('Détail de l\'alerte', style: tt.titleSmall),
    centerTitle: true,
  );

  Widget _buildAcknowledgeButton(TextTheme tt, String? alertId) {
    if (_acknowledged) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text(
              'Alerte comprise',
              style: tt.bodyLarge?.copyWith(color: AppColors.success, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: alertId == null
            ? null
            : () async {
                await context.read<AlertProvider>().acknowledgeAlert(alertId);
                if (mounted) setState(() => _acknowledged = true);
              },
        icon: const Icon(Icons.volume_off, size: 18),
        label: const Text('J\'ai compris — ne plus alerter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildIgnoreButton(TextTheme tt) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _ignoreZone,
        icon: const Icon(Icons.visibility_off, size: 18),
        label: const Text('Ignorer cette zone'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _castVote(String alertId, String vote) async {
    setState(() => _voting = true);
    try {
      if (_isDangerZone) {
        await context.read<DangerZoneNotifier>().confirmDangerZone(alertId);
        if (mounted) setState(() => _localConfirmations++);
      } else {
        final provider = context.read<AlertProvider>();
        if (vote == 'confirm') {
          await provider.confirmAlert(alertId);
          if (mounted) setState(() => _localConfirmations++);
        } else {
          await provider.denyAlert(alertId);
        }
      }
      if (mounted) setState(() => _vote = vote);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du vote. Réessaie.')),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  void _reportAbuse(String alertId) {
    if (_isDangerZone && _dangerZone != null) {
      final notifier = context.read<DangerZoneNotifier>();
      final title = _dangerZone!.title;
      showDialog(
        context: context,
        builder: (ctx) => ReportAbuseDialog(
          zoneId: alertId,
          zoneTitle: title,
          onReport: (reason) async {
            await notifier.reportDangerZoneAbuse(alertId, reason);
          },
        ),
      );
    } else {
      _reportCommunityAlert(alertId);
    }
  }

  Future<void> _reportCommunityAlert(String alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler comme abusif ?'),
        content: const Text(
            'Cette alerte sera examinée et pourra être supprimée si elle ne respecte pas les règles.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Signaler', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    }
  }

  void _ignoreZone() {
    final zone = _dangerZone;
    if (zone == null) return;
    final provider = context.read<IgnoredDangerZonesProvider>();
    showDialog(
      context: context,
      builder: (ctx) => IgnoreZoneDialog(
        zone: zone,
        onIgnore: (durationHours) async {
          final reason = durationHours == null
              ? 'Ignoré définitivement'
              : 'Ignoré pour ${durationHours}h';
          await provider.ignoreDangerZone(
            dangerZoneId: int.parse(zone.id),
            reason: reason,
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Color _gravityColor(String g) => switch (g) {
    'high'   => AppColors.gravityHigh,
    'medium' => AppColors.gravityMid,
    _        => AppColors.gravityLow,
  };

  String _gravityLabel(String g) => switch (g) {
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

// ─── Mini-carte ───────────────────────────────────────────────────────────────

class _MiniMap extends StatelessWidget {
  final double lat;
  final double lng;
  final double radius;
  final Color color;

  const _MiniMap({required this.lat, required this.lng, required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(lat, lng),
          zoom: 15,
        ),
        circles: {
          gmaps.Circle(
            circleId: const gmaps.CircleId('zone'),
            center: gmaps.LatLng(lat, lng),
            radius: radius,
            fillColor: color.withValues(alpha: 0.15),
            strokeColor: color,
            strokeWidth: 2,
          ),
        },
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
      ),
    );
  }
}

// ─── Chip vote ────────────────────────────────────────────────────────────────

class _VoteChip extends StatelessWidget {
  final String vote;
  const _VoteChip({required this.vote});

  @override
  Widget build(BuildContext context) {
    final isConfirm = vote == 'confirm';
    final color = isConfirm ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isConfirm ? Icons.check_circle_outline : Icons.do_not_disturb_on_outlined;
    final label = isConfirm ? 'Confirmé — merci pour ton signalement' : 'Vote enregistré';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
