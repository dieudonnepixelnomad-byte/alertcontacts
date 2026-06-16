import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/colors.dart';
import '../../../core/models/zone.dart';
import '../../../core/models/contact_relation.dart';
import '../providers/zones_notifier.dart';
import '../../proches/providers/relationship_provider.dart';

class AssignContactsSheet extends StatefulWidget {
  final Zone zone;

  const AssignContactsSheet({super.key, required this.zone});

  @override
  State<AssignContactsSheet> createState() => _AssignContactsSheetState();
}

class _AssignContactsSheetState extends State<AssignContactsSheet> {
  late Set<String> _selected;
  String _search = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.zone.memberIds ?? []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final relProvider = context.read<RelationshipProvider>();
      log('[AssignSheet] initState — contacts count: ${relProvider.acceptedRelationships.length}');
      if (relProvider.acceptedRelationships.isEmpty && !relProvider.isLoading) {
        log('[AssignSheet] contacts empty → initialize() then loadRelationships()');
        relProvider.initialize().then((_) => relProvider.loadRelationships());
      }
    });
  }

  bool get _hasChanges {
    final current = Set<String>.from(widget.zone.memberIds ?? []);
    return !_selected.containsAll(current) || !current.containsAll(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final relProvider = context.watch<RelationshipProvider>();
    final contacts = relProvider.acceptedRelationships;

    log('[AssignSheet] RelationshipProvider hashCode: ${relProvider.hashCode}');
    log('[AssignSheet] acceptedRelationships count: ${contacts.length}');
    log('[AssignSheet] contacts: ${contacts.map((c) => "${c.contact.id}:${c.contact.name}").toList()}');
    log('[AssignSheet] zone.memberIds: ${widget.zone.memberIds}');

    final alreadyIn = contacts
        .where((c) => (widget.zone.memberIds ?? []).contains(c.contact.id))
        .toList();
    final others = contacts
        .where((c) => !(widget.zone.memberIds ?? []).contains(c.contact.id))
        .toList();

    log('[AssignSheet] alreadyIn: ${alreadyIn.length}, others: ${others.length}');

    final filteredIn = _search.isEmpty
        ? alreadyIn
        : alreadyIn
            .where((c) =>
                c.contact.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();
    final filteredOthers = _search.isEmpty
        ? others
        : others
            .where((c) =>
                c.contact.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final totalContacts = contacts.length;
    final selCount = _selected.length;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
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

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _ZoneIconBadge(zone: widget.zone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Affecter un proche',
                          style: tt.titleSmall),
                      Text(
                        '${widget.zone.name.toUpperCase()} · ${widget.zone.radiusMeters.toInt()} M',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un proche...',
                hintStyle:
                    tt.bodyMedium?.copyWith(color: AppColors.gray400),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.gray400),
                filled: true,
                fillColor: AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selection count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'SÉLECTION · $selCount/$totalContacts',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.06,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Contact list (scrollable)
          Flexible(
            child: relProvider.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              children: [
                if (filteredIn.isNotEmpty) ...[
                  _SectionLabel(
                      'DÉJÀ DANS LA ZONE · ${filteredIn.length}'),
                  ...filteredIn.map((rel) => _ContactTile(
                        relation: rel,
                        isSelected: _selected.contains(rel.contact.id),
                        isAlreadyAssigned: true,
                        onTap: () => setState(() {
                          if (_selected.contains(rel.contact.id)) {
                            _selected.remove(rel.contact.id);
                          } else {
                            _selected.add(rel.contact.id);
                          }
                        }),
                      )),
                ],
                if (filteredOthers.isNotEmpty) ...[
                  _SectionLabel(
                      'AUTRES PROCHES · ${filteredOthers.length}'),
                  ...filteredOthers.map((rel) => _ContactTile(
                        relation: rel,
                        isSelected: _selected.contains(rel.contact.id),
                        isAlreadyAssigned: false,
                        onTap: () => setState(() {
                          if (_selected.contains(rel.contact.id)) {
                            _selected.remove(rel.contact.id);
                          } else {
                            _selected.add(rel.contact.id);
                          }
                        }),
                      )),
                ],
                if (filteredIn.isEmpty && filteredOthers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucun proche trouvé',
                        style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Validate button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_hasChanges && !_saving) ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.gray200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Valider',
                        style: tt.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context
        .read<ZonesNotifier>()
        .assignContactsToZone(widget.zone, _selected.toList());
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de sauvegarder les assignations')),
        );
      }
    }
  }
}

// ─── Zone Icon Badge ──────────────────────────────────────────────────────────

class _ZoneIconBadge extends StatelessWidget {
  final Zone zone;
  const _ZoneIconBadge({required this.zone});

  static const _iconMap = {
    'home': (Icons.home_rounded, Color(0xFFFFEBEE), Color(0xFFE53935)),
    'school': (Icons.school_rounded, Color(0xFFFFF3E0), Color(0xFFE65100)),
    'work': (Icons.work_rounded, Color(0xFFEDE7F6), Color(0xFF7B1FA2)),
    'sport': (Icons.sports_rounded, Color(0xFFE3F2FD), Color(0xFF1565C0)),
    'shopping':
        (Icons.shopping_bag_rounded, Color(0xFFFCE4EC), Color(0xFFC2185B)),
    'other': (Icons.location_on_rounded, AppColors.primaryLight, AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final key = zone.iconKey ?? 'other';
    final (icon, bg, color) = _iconMap[key] ?? _iconMap['other']!;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.gray400,
              letterSpacing: 0.06,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─── Contact Tile ─────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final ContactRelation relation;
  final bool isSelected;
  final bool isAlreadyAssigned;
  final VoidCallback onTap;

  const _ContactTile({
    required this.relation,
    required this.isSelected,
    required this.isAlreadyAssigned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final name = relation.contact.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = relation.contact.avatarUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(initial,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  if (!isAlreadyAssigned && isSelected)
                    Text(
                      'Sera notifié(e) à l\'ajout',
                      style: tt.labelSmall
                          ?.copyWith(color: const Color(0xFFF97316)),
                    )
                  else if (isAlreadyAssigned)
                    Text(
                      isSelected ? 'Déjà dans la zone' : 'Sera retiré(e) de la zone',
                      style: tt.labelSmall?.copyWith(
                        color: isSelected ? AppColors.gray400 : AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),

            // Checkbox
            _CheckIcon(selected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  final bool selected;
  const _CheckIcon({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.gray200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: selected
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }
}
