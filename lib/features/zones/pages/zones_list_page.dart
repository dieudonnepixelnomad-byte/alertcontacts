import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/zone.dart';
import '../../../theme/colors.dart';
import '../providers/zones_notifier.dart';
import '../widgets/zone_card.dart';
import 'zone_details_page.dart';

class ZonesListPage extends StatefulWidget {
  const ZonesListPage({super.key});

  @override
  State<ZonesListPage> createState() => _ZonesListPageState();
}

class _ZonesListPageState extends State<ZonesListPage> {
  final TextEditingController _searchController = TextEditingController();
  ZoneType? _currentFilter; // null = toutes, ZoneType.safe = sécurité, ZoneType.danger = danger

  @override
  void initState() {
    super.initState();
    log('ZoneListPage: InitState - Initialisation de la page');

    // Charger les zones au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('ZoneListPage: AddPostFrameCallback - Chargement des zones');
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche temporaire
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
                              backgroundColor: AppColors.teal.withOpacity(0.1),
                              foregroundColor: AppColors.teal,
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
          Expanded(
            child: _buildZonesList(_currentFilter),
          ),
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

        // Filtrer les zones selon l'onglet
        List<Zone> zones = notifier.filteredZones;
        if (filterType != null) {
          zones = zones.where((zone) => zone.type == filterType).toList();
        }

        if (zones.isEmpty) {
          return _buildEmptyState(filterType);
        }

        return RefreshIndicator(
          onRefresh: () => notifier.refreshZones(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
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
    String title;
    String subtitle;
    IconData icon;

    switch (filterType) {
      case ZoneType.safe:
        title = 'Aucune zone de sécurité';
        subtitle =
            'Créez votre première zone de sécurité pour protéger vos proches';
        icon = Icons.shield_outlined;
        break;
      case ZoneType.danger:
        title = 'Aucune zone de danger';
        subtitle = 'Signalez des zones dangereuses pour aider la communauté';
        icon = Icons.warning_outlined;
        break;
      default:
        title = 'Aucune zone créée';
        subtitle = 'Commencez par créer votre première zone';
        icon = Icons.location_on_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ZonesNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              notifier.errorMessage ?? 'Une erreur est survenue',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneDetails(Zone zone) {
    // TODO: Implémenter l'affichage des détails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails de ${zone.name} - À implémenter')),
    );
  }

  void _deleteZone(Zone zone) {
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
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );

              // La liste se mettra à jour automatiquement grâce au Consumer
              // Pas besoin de recharger manuellement
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _viewZoneDetails(Zone zone) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ZoneDetailsPage(zone: zone),
      ),
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
              trailing: _currentFilter == null ? const Icon(Icons.check, color: AppColors.teal) : null,
              onTap: () {
                setState(() => _currentFilter = null);
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield, color: Colors.green),
              title: const Text('Zones de sécurité'),
              trailing: _currentFilter == ZoneType.safe ? const Icon(Icons.check, color: AppColors.teal) : null,
              onTap: () {
                setState(() => _currentFilter = ZoneType.safe);
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Zones de danger'),
              trailing: _currentFilter == ZoneType.danger ? const Icon(Icons.check, color: AppColors.teal) : null,
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
