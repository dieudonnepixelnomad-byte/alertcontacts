import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import '../../../theme/colors.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/models/zone.dart' as zone_models;
import '../../../core/providers/map_type_notifier.dart';
import '../../../core/services/contact_rtdb_service.dart';
import 'permissions_modal.dart';

class ContactBottomSheet extends StatefulWidget {
  final ContactRelation relation;
  final RtdbContactSnapshot? snapshot;
  final List<zone_models.Zone> safeZones;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onResendInvitation;
  final VoidCallback? onActivateSharing;
  final VoidCallback onRemove;
  final Future<bool> Function({
    required bool sharePosition,
    required bool shareBattery,
    required bool shareZoneEvents,
    required bool shareSpeed,
  }) onSavePermissions;

  const ContactBottomSheet({
    super.key,
    required this.relation,
    required this.onRemove,
    required this.onSavePermissions,
    this.snapshot,
    this.safeZones = const [],
    this.onViewOnMap,
    this.onResendInvitation,
    this.onActivateSharing,
  });

  @override
  State<ContactBottomSheet> createState() => _ContactBottomSheetState();
}

class _ContactBottomSheetState extends State<ContactBottomSheet> {
  gmaps.GoogleMapController? _mapCtrl;

  zone_models.Zone? get _currentZone {
    final snap = widget.snapshot;
    if (snap == null) return null;
    for (final z in widget.safeZones) {
      if (_haversine(snap.latitude, snap.longitude, z.center.lat, z.center.lng) <= z.radiusMeters) {
        return z;
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

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'à l\'instant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}j';
  }

  // Header subtitle: "✓ Active · Zone" or status
  ({String text, Color color}) get _headerStatus {
    final snap = widget.snapshot;
    final isPending = widget.relation.status == RelationStatus.pending;
    if (isPending) {
      return (text: 'Invitation en attente', color: AppColors.gray400);
    }
    if (snap == null) {
      return (text: 'Hors ligne', color: AppColors.gray400);
    }
    if (snap.isInvisible) {
      return (text: 'Position en pause', color: const Color(0xFFFF8C3C));
    }
    final age = DateTime.now().difference(snap.updatedAt);
    if (age > const Duration(minutes: 30)) {
      return (text: 'Hors ligne · vu il y a ${_timeAgo(snap.updatedAt)}', color: AppColors.gray400);
    }
    final zone = _currentZone;
    if (zone != null) {
      return (text: '✓ Active · ${zone.name}', color: AppColors.success);
    }
    return (text: '✓ Active', color: AppColors.success);
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rel = widget.relation;
    final liveSnap = rel.contact.firebaseUid != null
        ? context.watch<ContactRtdbService>().snapshots[rel.contact.firebaseUid!]
        : null;
    final snap = liveSnap ?? widget.snapshot;
    final isPending = rel.status == RelationStatus.pending;
    final battery = rel.batteryLevel;
    final speed = snap?.speedKmh;
    final lastUpdate = snap?.updatedAt;
    final name = rel.contact.name;
    final firstName = name.split(' ').first;
    final status = _headerStatus;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            // Handle
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Mini-map
            if (snap != null)
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    gmaps.GoogleMap(
                      initialCameraPosition: gmaps.CameraPosition(
                        target: gmaps.LatLng(snap.latitude, snap.longitude),
                        zoom: 15,
                      ),
                      onMapCreated: (ctrl) => _mapCtrl = ctrl,
                      mapType: context.watch<MapTypeNotifier>().type,
                      markers: {
                        gmaps.Marker(
                          markerId: const gmaps.MarkerId('contact'),
                          position: gmaps.LatLng(snap.latitude, snap.longitude),
                          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                            gmaps.BitmapDescriptor.hueCyan,
                          ),
                        ),
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 100,
                color: AppColors.gray100,
                child: const Center(
                  child: Icon(Icons.location_off_outlined, color: AppColors.gray400, size: 32),
                ),
              ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),

                  // Avatar + nom + status
                  Row(
                    children: [
                      _Avatar(
                        avatarUrl: rel.contact.avatarUrl,
                        name: name,
                        isPending: isPending,
                        radius: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: tt.titleSmall?.copyWith(fontSize: 18)),
                            const SizedBox(height: 3),
                            Text(
                              status.text,
                              style: tt.bodySmall?.copyWith(
                                color: status.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Stats row (batterie, vitesse, MAJ)
                  if (!isPending && (battery != null || speed != null || lastUpdate != null)) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          if (battery != null)
                            _StatCell(
                              label: 'BATTERIE',
                              value: '$battery%',
                              icon: Icons.battery_charging_full_rounded,
                              iconColor: battery < 20 ? AppColors.danger : AppColors.success,
                            ),
                          if (battery != null && (speed != null || lastUpdate != null))
                            _VerticalDivider(),
                          if (speed != null)
                            _StatCell(
                              label: 'VITESSE',
                              value: '${speed.toStringAsFixed(0)} km/h',
                              icon: Icons.speed_rounded,
                              iconColor: AppColors.gray400,
                            ),
                          if (speed != null && lastUpdate != null) _VerticalDivider(),
                          if (lastUpdate != null)
                            _StatCell(
                              label: 'MAJ',
                              value: _timeAgo(lastUpdate),
                              icon: Icons.refresh_rounded,
                              iconColor: AppColors.gray400,
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Action tiles ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        if (!isPending) ...[
                          if (rel.canSeeContact) ...[
                            _ActionTile(
                              icon: Icons.map_outlined,
                              label: 'Voir sur la carte',
                              subtitle: snap != null
                                  ? 'Centre la carte sur $firstName'
                                  : '$firstName est hors ligne',
                              onTap: snap != null && widget.onViewOnMap != null
                                  ? () {
                                      Navigator.pop(context);
                                      widget.onViewOnMap!();
                                    }
                                  : () {},
                            ),
                          ] else ...[
                            _ActionTile(
                              icon: Icons.location_off_outlined,
                              label: 'Position non visible',
                              subtitle: '$firstName n\'a pas activé le partage',
                              showChevron: false,
                              onTap: () {},
                            ),
                          ],
                          _TileDivider(),
                          if (!rel.canSeeMe) ...[
                            _ActionTile(
                              icon: Icons.share_location_outlined,
                              label: 'Partager ma position avec $firstName',
                              subtitle: '$firstName ne peut pas te voir pour le moment',
                              onTap: () {
                                Navigator.pop(context);
                                widget.onActivateSharing?.call();
                              },
                            ),
                            _TileDivider(),
                          ],
                          _ActionTile(
                            icon: Icons.notifications_outlined,
                            label: 'Gérer les alertes',
                            subtitle: 'Quelles alertes recevoir',
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Disponible prochainement')),
                              );
                            },
                          ),
                          _TileDivider(),
                          _ActionTile(
                            icon: Icons.tune_outlined,
                            label: 'Permissions de partage',
                            subtitle: 'Ce qu\'il peut voir de toi',
                            onTap: () => _openPermissions(context),
                          ),
                          _TileDivider(),
                        ],
                        if (isPending && widget.onResendInvitation != null) ...[
                          _ActionTile(
                            icon: Icons.send_outlined,
                            label: 'Renvoyer l\'invitation',
                            subtitle: 'Rappeler à $firstName de rejoindre',
                            onTap: () {
                              Navigator.pop(context);
                              widget.onResendInvitation!();
                            },
                          ),
                          _TileDivider(),
                        ],
                        // Destructive — always last
                        _ActionTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Retirer $firstName',
                          subtitle: 'Action irréversible',
                          onTap: () => _confirmRemove(context),
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPermissions(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PermissionsModal(
        contactName: widget.relation.contact.name,
        avatarUrl: widget.relation.contact.avatarUrl,
        acceptedAt: widget.relation.acceptedAt,
        sharePosition: true,
        shareBattery: true,
        shareZoneEvents: true,
        shareSpeed: false,
        onSave: widget.onSavePermissions,
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final name = widget.relation.contact.name;
    final firstName = name.split(' ').first;
    Navigator.pop(context);
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _RemoveConfirmDialog(firstName: firstName),
    ).then((ok) {
      if (ok == true) widget.onRemove();
    });
  }
}

// ─── Remove Confirmation Dialog ──────────────────────────────────────────────

class _RemoveConfirmDialog extends StatelessWidget {
  final String firstName;
  const _RemoveConfirmDialog({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Retirer $firstName ?',
              style: tt.titleSmall?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Vous ne verrez plus mutuellement vos positions. Vos zones partagées seront supprimées.',
              style: tt.bodySmall?.copyWith(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Warning banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$firstName sera notifié(e). Tu pourras le réinviter plus tard.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // CTA rouge
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Oui, retirer $firstName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Annuler',
                style: tt.bodyMedium?.copyWith(color: AppColors.gray600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.gray400,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.gray200);
  }
}

class _TileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, endIndent: 0, color: Color(0xFFE5E7EB));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = isDestructive ? AppColors.danger : AppColors.gray600;
    final textColor = isDestructive ? AppColors.danger : AppColors.gray900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: tt.labelMedium?.copyWith(color: AppColors.gray400),
                    ),
                ],
              ),
            ),
            if (!isDestructive && showChevron)
              const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final bool isPending;
  final double radius;
  const _Avatar({
    required this.avatarUrl,
    required this.name,
    this.isPending = false,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.65,
              ),
            )
          : null,
    );
    if (isPending) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: avatar,
      );
    }
    return avatar;
  }
}
