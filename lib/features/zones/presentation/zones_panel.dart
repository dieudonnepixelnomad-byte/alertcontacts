import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/colors.dart';
import '../../../core/models/zone.dart';
import '../../../core/models/contact_relation.dart';
import '../providers/zones_notifier.dart';
import '../../proches/providers/relationship_provider.dart';
import 'zone_creation_wizard.dart';
import 'assign_contacts_sheet.dart';

class ZonesPanel extends StatefulWidget {
  const ZonesPanel({super.key});

  @override
  State<ZonesPanel> createState() => _ZonesPanelState();
}

class _ZonesPanelState extends State<ZonesPanel> {
  @override
  void initState() {
    super.initState();
    log('[ZonesPanel] initState — panneau ouvert');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<ZonesNotifier>();
      log('[ZonesPanel] postFrameCallback — status=${notifier.status}, isLoading=${notifier.isLoading}');
      if (!notifier.isLoading) {
        log('[ZonesPanel] → appel loadZones()');
        notifier.loadZones();
      } else {
        log('[ZonesPanel] → loadZones() déjà en cours, skip');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.88,
            height: double.infinity,
            child: Consumer2<ZonesNotifier, RelationshipProvider>(
              builder: (context, zonesNotifier, relProvider, _) {
                final safeZones = zonesNotifier.safeZones;
                final contacts = relProvider.acceptedRelationships;
                log('[ZonesPanel] build — status=${zonesNotifier.status} isLoading=${zonesNotifier.isLoading} hasError=${zonesNotifier.hasError} safeZones=${safeZones.length} allZones=${zonesNotifier.zones.length}');

                // Compute header subtitle
                final uniqueMembers = <String>{};
                for (final z in safeZones) {
                  if (z.memberIds != null) uniqueMembers.addAll(z.memberIds!);
                }
                final zoneCount = safeZones.length;
                final memberCount = uniqueMembers.length;
                final subtitleParts = <String>[];
                if (zoneCount > 0) subtitleParts.add('$zoneCount ZONE${zoneCount > 1 ? 'S' : ''}');
                if (memberCount > 0) subtitleParts.add('$memberCount PROCHE${memberCount > 1 ? 'S' : ''} ASSOCIÉ${memberCount > 1 ? 'S' : ''}');
                final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' · ');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPad + 8),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mes zones', style: tt.titleLarge),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: tt.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      letterSpacing: 0.06,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            onPressed: () => Navigator.pop(context),
                            color: AppColors.gray400,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: zonesNotifier.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : zonesNotifier.hasError
                              ? _ErrorState(
                                  message: zonesNotifier.errorMessage ?? 'Erreur',
                                  onRetry: () => zonesNotifier.loadZones(),
                                )
                              : safeZones.isEmpty
                                  ? const _EmptyState()
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      itemCount: safeZones.length,
                                      separatorBuilder: (_, __) => const Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                      itemBuilder: (_, i) => _ZoneRow(
                                        zone: safeZones[i],
                                        contacts: contacts,
                                      ),
                                    ),
                    ),

                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _CreateZoneButton(
                        onTap: () => _openCreationWizard(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openCreationWizard(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        builder: (_, controller) => ZoneCreationWizard(scrollController: controller),
      ),
    );
  }
}

// ─── Zone Row (design: icon + name + radius/address + dot + members) ─────────

class _ZoneRow extends StatelessWidget {
  final Zone zone;
  final List<ContactRelation> contacts;

  const _ZoneRow({required this.zone, required this.contacts});

  static const _iconMap = {
    'home':     (Icons.home_rounded,          Color(0xFFFFEBEE), Color(0xFFE53935)),
    'school':   (Icons.school_rounded,         Color(0xFFFFF3E0), Color(0xFFE65100)),
    'work':     (Icons.work_rounded,           Color(0xFFEDE7F6), Color(0xFF7B1FA2)),
    'sport':    (Icons.sports_rounded,         Color(0xFFE3F2FD), Color(0xFF1565C0)),
    'shopping': (Icons.shopping_bag_rounded,   Color(0xFFFCE4EC), Color(0xFFC2185B)),
    'other':    (Icons.location_on_rounded,    AppColors.primaryLight, AppColors.primary),
  };

  (IconData, Color, Color) get _iconData {
    final key = zone.iconKey ?? 'other';
    final entry = _iconMap[key];
    return entry ?? _iconMap['other']!;
  }

  // Contacts associated with this zone via memberIds
  List<ContactRelation> get _zoneContacts {
    final ids = zone.memberIds;
    if (ids == null || ids.isEmpty) return [];
    return contacts.where((c) => ids.contains(c.contact.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (icon, bgColor, iconColor) = _iconData;
    final zoneContacts = _zoneContacts;
    final memberCount = zone.memberIds?.length ?? 0;

    return InkWell(
      onTap: () => _openAssignSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Name + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: tt.labelMedium?.copyWith(color: AppColors.gray400),
                  ),
                  if (memberCount > 0) ...[
                    const SizedBox(height: 6),
                    _MembersRow(contacts: zoneContacts, totalCount: memberCount),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAssignSheet(BuildContext context) {
    final zonesNotifier = context.read<ZonesNotifier>();
    final relProvider = context.read<RelationshipProvider>();
    log('[ZonesPanel] opening assign sheet for zone: ${zone.id} "${zone.name}"');
    log('[ZonesPanel] relProvider hashCode: ${relProvider.hashCode}');
    log('[ZonesPanel] acceptedRelationships count: ${relProvider.acceptedRelationships.length}');
    log('[ZonesPanel] contacts: ${relProvider.acceptedRelationships.map((c) => "${c.contact.id}:${c.contact.name}").toList()}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ZonesNotifier>.value(value: zonesNotifier),
          ChangeNotifierProvider<RelationshipProvider>.value(value: relProvider),
        ],
        child: AssignContactsSheet(zone: zone),
      ),
    );
  }

  String get _subtitle {
    final radius = '${zone.radiusMeters.toInt()} m';
    final addr = zone.address;
    if (addr != null && addr.isNotEmpty) return '$radius · $addr';
    return radius;
  }
}

// ─── Members Row ─────────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  final List<ContactRelation> contacts;
  final int totalCount;

  const _MembersRow({required this.contacts, required this.totalCount});

  static const _avatarColors = [
    Color(0xFF1E6868),
    Color(0xFFE65100),
    Color(0xFF7B1FA2),
    Color(0xFF1565C0),
    Color(0xFFC2185B),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final shown = contacts.take(3).toList();

    return Row(
      children: [
        // Avatar chips
        ...shown.asMap().entries.map((e) {
          final i = e.key;
          final rel = e.value;
          final initial = rel.contact.name.isNotEmpty ? rel.contact.name[0].toUpperCase() : '?';
          final color = _avatarColors[i % _avatarColors.length];
          return Padding(
            padding: EdgeInsets.only(right: i < shown.length - 1 ? 4 : 8),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),

        // If contacts are linked
        if (contacts.isNotEmpty)
          Text(
            '${contacts.length}/$totalCount en zone',
            style: tt.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
          )
        else
          Text(
            '$totalCount proche${totalCount > 1 ? 's' : ''}',
            style: tt.labelMedium?.copyWith(color: AppColors.gray400),
          ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text('Aucune zone créée', style: tt.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Crée ta première zone pour recevoir des alertes quand tes proches arrivent ou partent.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 40, color: AppColors.gray400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: tt.bodySmall?.copyWith(color: AppColors.gray400)),
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

// ─── Create Zone Button ───────────────────────────────────────────────────────

class _CreateZoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateZoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Créer une zone',
              style: tt.bodyLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
