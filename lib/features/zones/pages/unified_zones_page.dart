import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/zone.dart';
import '../../../theme/colors.dart';
import '../providers/zones_notifier.dart';
import '../widgets/zone_card.dart';
import 'zone_details_page.dart';

class UnifiedZonesPage extends StatefulWidget {
  const UnifiedZonesPage({super.key});

  @override
  State<UnifiedZonesPage> createState() => _UnifiedZonesPageState();
}

class _UnifiedZonesPageState extends State<UnifiedZonesPage> {
  final TextEditingController _searchController = TextEditingController();
  ZoneType?
  _currentFilter; // null = toutes, ZoneType.safe = sécurité, ZoneType.danger = danger

  @override
  void initState() {
    super.initState();
    log('UnifiedZonesPage: InitState - Initialisation de la page');

    // Charger les zones au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('UnifiedZonesPage: AddPostFrameCallback - Chargement des zones');
      context.read<ZonesNotifier>().loadZones();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: cs.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une zone...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    context.read<ZonesNotifier>().searchZones(query);
                  },
                ),
                const SizedBox(height: 12),
                // Filtres par type de zone
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showFilterDialog,
                        icon: const Icon(Icons.filter_list),
                        label: Text(_getFilterLabel()),
                        style: _currentFilter != null
                            ? OutlinedButton.styleFrom(
                                backgroundColor:
                                    cs.primary.withOpacity(0.1),
                                foregroundColor: cs.primary,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des zones filtrées
          Expanded(child: _buildZonesList(_currentFilter)),
        ],
      ),
    );
  }

  Widget _buildZonesList(ZoneType? filterType) {
    return Consumer<ZonesNotifier>(
      builder: (context, notifier, child) {
        if (notifier.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notifier.hasError) {
          return _buildErrorState(notifier);
        }

        // Filtrer les zones selon le filtre sélectionné
        List<Zone> zones = notifier.filteredZones;
        if (filterType != null) {
          zones = zones.where((zone) => zone.type == filterType).toList();
        }

        if (zones.isEmpty) {
          return _buildEmptyState(filterType);
        }

        return RefreshIndicator(
          onRefresh: () => notifier.refreshZones(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return ZoneCard(
                zone: zone,
                onTap: () => _viewZoneDetails(zone),
                onDelete: () => _deleteZone(zone),
                onDetails: () => _viewZoneDetails(zone),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ZoneType? filterType) {
    final cs = Theme.of(context).colorScheme;
    String title;
    String subtitle;
    IconData icon;

    switch (filterType) {
      case ZoneType.safe:
        title = 'Aucune zone de sécurité';
        subtitle =
            'Vos zones de sécurité apparaîtront ici.\nCréez-les depuis la carte principale.';
        icon = Icons.shield_outlined;
        break;
      case ZoneType.danger:
        title = 'Aucune zone de danger';
        subtitle =
            'Les zones de danger que vous signalez apparaîtront ici.\nCréez-les depuis la carte principale.';
        icon = Icons.warning_outlined;
        break;
      default:
        title = 'Aucune zone créée';
        subtitle =
            'Vos zones apparaîtront ici.\nCréez-les depuis la carte principale.';
        icon = Icons.location_on_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ZonesNotifier notifier) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              notifier.errorMessage ?? 'Une erreur est survenue',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => notifier.clearError(),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => notifier.loadZones(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteZone(Zone zone) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la zone'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${zone.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // Utiliser le context principal pour les opérations
              final notifier = context.read<ZonesNotifier>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await notifier.deleteZone(zone);

              // Afficher le message de résultat
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Zone "${zone.name}" supprimée avec succès'
                        : 'Erreur lors de la suppression',
                  ),
                  backgroundColor: success ? cs.primary : cs.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _viewZoneDetails(Zone zone) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ZoneDetailsPage(zone: zone)),
    );
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case ZoneType.safe:
        return 'Zones de sécurité';
      case ZoneType.danger:
        return 'Zones de danger';
      case null:
        return 'Toutes les zones';
    }
  }

  void _showFilterDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filtrer les zones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Toutes les zones'),
              trailing: _currentFilter == null
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () {
                setState(() => _currentFilter = null);
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.shield, color: cs.primary),
              title: const Text('Zones de sécurité'),
              trailing: _currentFilter == ZoneType.safe
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () {
                setState(() => _currentFilter = ZoneType.safe);
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: cs.error),
              title: const Text('Zones de danger'),
              trailing: _currentFilter == ZoneType.danger
                  ? Icon(Icons.check, color: cs.primary)
                  : null,
              onTap: () {
                setState(() => _currentFilter = ZoneType.danger);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
