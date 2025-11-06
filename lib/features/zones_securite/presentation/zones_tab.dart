// lib/features/zones_securite/presentation/zones_tab.dart
import 'package:flutter/material.dart';
import '../../../core/models/safe_zone.dart';

// Données FAKE
final _fakeZones = <SafeZone>[
  SafeZone(
    id: 'sz1',
    name: 'Maison',
    iconKey: 'home',
    address: 'Rue des Acacias, 12',
    center: const LatLng(3.8702, 11.5149),
    radiusMeters: 120,
    memberIds: const ['Marie', 'Lucas'],
  ),
  SafeZone(
    id: 'sz2',
    name: 'École',
    iconKey: 'school',
    address: 'Avenue de la Paix, 45',
    center: const LatLng(3.8712, 11.5159),
    radiusMeters: 80,
    memberIds: const ['Lucas'],
  ),
];

class ZonesTab extends StatefulWidget {
  const ZonesTab({super.key});
  @override
  State<ZonesTab> createState() => _ZonesTabState();
}

class _ZonesTabState extends State<ZonesTab> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _fakeZones.isEmpty
          ? _EmptyState(
              icon: Icons.shield_outlined,
              title: 'Aucune zone',
              subtitle: 'Créez votre première zone pour protéger vos proches.',
              cta: 'Créer une zone',
              onCta: _onCreateZone,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _fakeZones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ZoneCard(
                zone: _fakeZones[i],
                onTap: () => _openDetails(_fakeZones[i]),
                onEdit: () => _editZone(_fakeZones[i]),
                onDelete: () => _deleteZone(_fakeZones[i]),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton de création simplifié
          FloatingActionButton.extended(
            heroTag: "zones_fab",
            onPressed: () => _onCreateZone(),
            icon: const Icon(Icons.add),
            label: const Text('Créer une zone'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: cs.surface,
    );
  }

  void _onCreateZone() {
    // TODO: context.push('/zone-securite/create') (wizard)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Créer une zone (fake)')));
  }

  Future<void> _openDetails(SafeZone z) async {
    // Ouvrir les détails complets (plus de restriction premium)
    // TODO: ouvrir fiche avec historique entrées/sorties complet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Détails complets: ${z.name}')));
  }

  void _editZone(SafeZone z) {
    // TODO: ouvrir édition (nom, rayon, horaires)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Éditer: ${z.name}')));
  }

  void _deleteZone(SafeZone z) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la zone ?'),
        content: Text('"${z.name}" sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _fakeZones.removeWhere((e) => e.id == z.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zone supprimée')));
    }
  }
}

class _ZoneCard extends StatelessWidget {
  final SafeZone zone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ZoneCard({
    required this.zone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMultiContactZone = zone.memberIds.length > 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Icône de la zone
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(zone.iconKey),
              color: cs.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Infos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        zone.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Badge multi-contacts (toujours visible maintenant)
                    if (isMultiContactZone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Multi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  zone.address ?? 'Adresse non définie',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 12,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${zone.radiusMeters}m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.people_outline,
                      size: 12,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${zone.memberIds.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'details':
                  onTap();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Détails'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.shield;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onCta;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.add),
              label: Text(cta),
            ),
          ],
        ),
      ),
    );
  }
}
