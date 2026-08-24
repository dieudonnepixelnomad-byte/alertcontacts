import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/colors.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/zone.dart' as zone_models;
import '../providers/relationship_provider.dart';
import 'invite_contact_page.dart';
import '../../../features/paywall/presentation/paywall_page.dart';
import '../../../core/services/paywall_trigger_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/contact_rtdb_service.dart';
import '../../../features/zones/providers/zones_notifier.dart';
import '../../../features/app_shell/providers/navigation_provider.dart';
import '../../../shared/widgets/low_battery_banner.dart';
import 'contact_bottom_sheet.dart';

class ProchesTab extends StatefulWidget {
  const ProchesTab({super.key});
  @override
  State<ProchesTab> createState() => _ProchesTabState();
}

class _ProchesTabState extends State<ProchesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RelationshipProvider>();
      await provider.initialize();
      await provider.loadRelationships();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RelationshipProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _ErrorState(
              error: provider.error!,
              onRetry: provider.loadRelationships,
            );
          }

          return Consumer<ContactRtdbService>(
            builder: (context, rtdb, _) {
              final accepted = provider.acceptedRelationships;
              final pending = provider.pendingRelationships;
              final total = accepted.length + pending.length;
              final zones = context.read<ZonesNotifier>().safeZones;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      connectedCount: accepted.length,
                      pendingCount: pending.length,
                    ),
                  ),
                  // Banners batterie faible (< 20%)
                  ...accepted
                      .where((r) => (r.batteryLevel ?? 100) < 20)
                      .map((r) => SliverToBoxAdapter(
                            child: LowBatteryBanner(
                              contactName: r.contact.name,
                              batteryPercent: r.batteryLevel!,
                            ),
                          )),

                  if (total == 0)
                    const SliverFillRemaining(child: _EmptyState())
                  else ...[
                    if (accepted.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final rel = accepted[i];
                              final snap = rel.contact.firebaseUid != null
                                  ? rtdb.snapshots[rel.contact.firebaseUid!]
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ContactCard(
                                  relation: rel,
                                  snapshot: snap,
                                  zones: zones,
                                  onTap: () => _openSheet(rel, snap, zones),
                                ),
                              );
                            },
                            childCount: accepted.length,
                          ),
                        ),
                      ),
                    if (pending.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'EN ATTENTE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              letterSpacing: 0.08,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ContactCard(
                                relation: pending[i],
                                snapshot: null,
                                zones: zones,
                                onTap: () => _openSheet(pending[i], null, zones),
                              ),
                            ),
                            childCount: pending.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'proches_invite_fab',
        onPressed: _openInvite,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
    );
  }

  Future<void> _openInvite() async {
    final provider = context.read<RelationshipProvider>();
    final accepted = provider.acceptedRelationships;
    final profile = await PrefsService().getUserProfile();

    if (profile?.hasPremiumAccess != true &&
        PaywallTriggerService.checkContactLimit(accepted.length)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallPage(trigger: 'contact_limit'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InviteContactPage()),
    );
  }

  void _openSheet(
    ContactRelation relation,
    RtdbContactSnapshot? snapshot,
    List<zone_models.Zone> zones,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContactBottomSheet(
        relation: relation,
        snapshot: snapshot,
        safeZones: zones,
        onRemove: () => _remove(relation),
        onViewOnMap: () {
          final uid = relation.contact.firebaseUid;
          if (uid == null) return;
          final liveSnap = context.read<ContactRtdbService>().snapshots[uid];
          if (liveSnap == null) return;
          context.read<NavigationProvider>().focusContact(
            uid: uid,
            lat: liveSnap.latitude,
            lng: liveSnap.longitude,
          );
        },
        onActivateSharing: () => _activateSharing(relation),
        onSavePermissions: ({
          required sharePosition,
          required shareBattery,
          required shareZoneEvents,
          required shareSpeed,
        }) =>
            _savePermissions(
          relation.id,
          sharePosition: sharePosition,
          shareBattery: shareBattery,
          shareZoneEvents: shareZoneEvents,
          shareSpeed: shareSpeed,
        ),
      ),
    );
  }

  Future<bool> _savePermissions(
    String relationId, {
    required bool sharePosition,
    required bool shareBattery,
    required bool shareZoneEvents,
    required bool shareSpeed,
  }) async {
    final provider = context.read<RelationshipProvider>();
    try {
      await provider.updateShareLevel(relationId, ShareLevel.realtime);
      return true;
    } catch (e) {
      log('permissions update error: $e');
      return false;
    }
  }

  Future<void> _activateSharing(ContactRelation relation) async {
    final provider = context.read<RelationshipProvider>();
    try {
      await provider.updateShareLevel(relation.id, ShareLevel.realtime);
      await provider.loadRelationships();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position partagée avec ${relation.contact.name.split(' ').first}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible d\'activer le partage'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _remove(ContactRelation relation) async {
    final provider = context.read<RelationshipProvider>();
    final ok = await provider.deleteRelationship(relation.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Proche retiré' : (provider.error ?? 'Erreur')),
          backgroundColor: ok ? null : AppColors.danger,
        ),
      );
    }
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int connectedCount;
  final int pendingCount;
  const _Header({required this.connectedCount, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final parts = <String>[];
    if (connectedCount > 0) parts.add('$connectedCount CONNECTÉ${connectedCount > 1 ? 'S' : ''}');
    if (pendingCount > 0) parts.add('$pendingCount EN ATTENTE');
    final subtitle = parts.isEmpty ? 'AUCUN PROCHE' : parts.join(' · ');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proches', style: tt.titleLarge),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: tt.labelSmall?.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.06,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Card ───────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final ContactRelation relation;
  final RtdbContactSnapshot? snapshot;
  final List<zone_models.Zone> zones;
  final VoidCallback onTap;

  const _ContactCard({
    required this.relation,
    required this.snapshot,
    required this.zones,
    required this.onTap,
  });

  // ── State helpers ──────────────────────────────────────────────────────

  String get _cardState {
    if (relation.isPending) return 'pending';
    if (relation.isOneWay) return 'one-way';
    if (snapshot == null) return 'offline';
    if (snapshot!.isInvisible) return 'invisible';
    if (DateTime.now().difference(snapshot!.updatedAt) > const Duration(minutes: 30)) return 'offline';
    return 'active';
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l\'instant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}j';
  }

  String? get _currentZoneName {
    final snap = snapshot;
    if (snap == null) return null;
    for (final z in zones) {
      if (_haversine(snap.latitude, snap.longitude, z.center.lat, z.center.lng) <= z.radiusMeters) {
        return z.name;
      }
    }
    return null;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dl / 2) * math.sin(dl / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ── Status text + color ───────────────────────────────────────────────

  ({String text, Color color, IconData? icon}) _statusLine(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    switch (_cardState) {
      case 'pending':
        return (
          text: 'Invitation envoyée · il y a ${_timeAgo(relation.createdAt)}',
          color: muted,
          icon: null,
        );
      case 'one-way':
        return (text: 'Position non visible', color: muted, icon: null);
      case 'offline':
        final last = snapshot?.updatedAt;
        return (
          text: last != null ? 'Hors ligne · vue il y a ${_timeAgo(last)}' : 'Hors ligne',
          color: muted,
          icon: null,
        );
      case 'invisible':
        return (
          text: 'Position en pause',
          color: const Color(0xFFFF8C3C),
          icon: Icons.pause_circle_outline,
        );
      case 'active':
        final zoneName = _currentZoneName;
        if (zoneName != null) {
          return (
            text: '✓ $zoneName · ${_timeAgo(snapshot!.updatedAt)}',
            color: AppColors.success,
            icon: null,
          );
        }
        final speed = snapshot!.speedKmh;
        if (speed != null && speed > 5) {
          return (
            text: 'En déplacement · ${speed.toStringAsFixed(0)} km/h',
            color: muted,
            icon: null,
          );
        }
        return (
          text: 'Actif · ${_timeAgo(snapshot!.updatedAt)}',
          color: muted,
          icon: null,
        );
      default:
        return (text: '', color: muted, icon: null);
    }
  }

  // ── Right indicator ───────────────────────────────────────────────────

  Widget _buildRightIndicator(BuildContext context) {
    switch (_cardState) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Renvoyer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        );
      case 'active':
      case 'invisible':
        final bat = relation.batteryLevel;
        if (bat == null) return const SizedBox.shrink();
        final batColor = bat < 20
            ? AppColors.danger
            : bat < 40
                ? AppColors.warning
                : Theme.of(context).colorScheme.onSurfaceVariant;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bat < 20 ? Icons.battery_alert_rounded : Icons.battery_full_rounded,
              size: 14,
              color: batColor,
            ),
            const SizedBox(width: 2),
            Text(
              '$bat%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: batColor,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Avatar badge (dot or clock) ───────────────────────────────────────

  Widget? _buildAvatarBadge(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final mutedBg = Theme.of(context).colorScheme.surfaceContainerHighest;
    switch (_cardState) {
      case 'active':
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 1.5),
          ),
        );
      case 'invisible':
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C3C),
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 1.5),
          ),
          child: const Icon(Icons.pause_rounded, size: 10, color: Colors.white),
        );
      case 'pending':
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: mutedBg,
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 1.5),
          ),
          child: Icon(Icons.schedule_rounded, size: 11, color: muted),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isPending = _cardState == 'pending';
    final isOfflineOrOneWay = _cardState == 'offline' || _cardState == 'one-way';
    final status = _statusLine(context);
    final badge = _buildAvatarBadge(context);

    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: isPending ? null : Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // ── Avatar + badge ─────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarCircle(
                avatarUrl: relation.contact.avatarUrl,
                name: relation.contact.name,
                faded: isPending || isOfflineOrOneWay,
              ),
              if (badge != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: badge,
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Name + status ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relation.contact.name,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (status.text.isNotEmpty)
                  Row(
                    children: [
                      if (status.icon != null) ...[
                        Icon(status.icon, size: 13, color: status.color),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          status.text,
                          style: tt.labelMedium?.copyWith(color: status.color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Right indicator (battery / chip) ───────────────────────────
          _buildRightIndicator(context),
        ],
      ),
    );

    // Dashed border for pending
    if (isPending) {
      card = CustomPaint(
        painter: _DashedRoundedBorderPainter(color: cs.outlineVariant),
        child: card,
      );
    }

    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── Dashed border painter ──────────────────────────────────────────────────

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedRoundedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const r = Radius.circular(14);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        r,
      ));
    const dashLen = 6.0;
    const gapLen = 4.0;
    final metric = path.computeMetrics().first;
    double dist = 0;
    while (dist < metric.length) {
      canvas.drawPath(metric.extractPath(dist, dist + dashLen), paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Avatar Circle ──────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final bool faded;
  const _AvatarCircle({required this.avatarUrl, required this.name, this.faded = false});

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            )
          : null,
    );
    if (!faded) return avatar;
    return Opacity(opacity: 0.4, child: avatar);
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_outlined, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Aucun proche pour l\'instant', style: tt.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Invite quelqu\'un pour partager vos positions et recevoir des alertes mutuellement.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Impossible de charger', style: tt.titleSmall),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
