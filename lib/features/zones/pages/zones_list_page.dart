import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/zone.dart';
import '../providers/zones_notifier.dart';
import '../providers/zones_state.dart';
import '../widgets/zone_card.dart';

class ZonesListPage extends StatefulWidget {
  const ZonesListPage({super.key});

  @override
  State<ZonesListPage> createState() => _ZonesListPageState();
}

class _ZonesListPageState extends State<ZonesListPage> {
  final _searchController = TextEditingController();
  ZoneType? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          _buildSearchBar(context, cs),
          Expanded(
            child: Consumer<ZonesNotifier>(
              builder: (context, notifier, child) {
                switch (notifier.status) {
                  case ZonesStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ZonesStatus.error:
                    return _buildErrorState(
                      cs,
                      message: notifier.errorMessage ?? 'Erreur inconnue',
                      onRetry: () => notifier.loadZones(),
                    );
                  case ZonesStatus.loaded:
                    final zones = notifier.filteredZones;
                    if (zones.isEmpty) {
                      return _buildEmptyState(
                        cs,
                        icon: Icons.map_outlined,
                        message: 'Aucune zone trouvée.',
                        subMessage:
                            'Créez une zone de sécurité ou explorez les zones de danger.',
                      );
                    }
                    return _buildZonesList(context, zones, cs);
                  default:
                    return _buildEmptyState(
                      cs,
                      icon: Icons.hourglass_empty,
                      message: 'Chargement des zones...',
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme cs) {
    final notifier = context.read<ZonesNotifier>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une zone...',
                  prefixIcon:
                      Icon(Icons.search, color: cs.onSurface.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: notifier.searchZones,
              ),
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: cs.primary),
              onPressed: () => _showFilterDialog(context, cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesList(
      BuildContext context, List<Zone> zones, ColorScheme cs) {
    final notifier = context.read<ZonesNotifier>();
    return RefreshIndicator(
      onRefresh: notifier.loadZones,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          return ZoneCard(
            zone: zone,
            onTap: () => context.push('/zone-details', extra: zone),
            onDelete: () => _confirmDelete(context, zone, cs),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme cs, {
    required IconData icon,
    required String message,
    String? subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ColorScheme cs, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: cs.error.withOpacity(0.7), size: 64),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ColorScheme cs) {
    final notifier = context.read<ZonesNotifier>();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtrer les zones'),
              content: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Toutes'),
                    selected: _filter == null,
                    onSelected: (_) {
                      setDialogState(() => _filter = null);
                      notifier.filterByType(null);
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    label: Text('Sécurité', style: TextStyle(color: cs.primary)),
                    selected: _filter == ZoneType.safe,
                    onSelected: (_) {
                      setDialogState(() => _filter = ZoneType.safe);
                      notifier.filterByType(ZoneType.safe);
                      Navigator.pop(context);
                    },
                    avatar: Icon(Icons.security, color: cs.primary),
                  ),
                  FilterChip(
                    label: Text('Danger', style: TextStyle(color: cs.error)),
                    selected: _filter == ZoneType.danger,
                    onSelected: (_) {
                      setDialogState(() => _filter = ZoneType.danger);
                      notifier.filterByType(ZoneType.danger);
                      Navigator.pop(context);
                    },
                    avatar: Icon(Icons.warning_amber, color: cs.error),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Zone zone, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer la zone "${zone.name}" ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteZone(context, zone, cs);
              },
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteZone(
      BuildContext context, Zone zone, ColorScheme cs) async {
    final notifier = context.read<ZonesNotifier>();
    try {
      await notifier.deleteZone(zone);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Zone "${zone.name}" supprimée.'),
            backgroundColor: cs.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : ${e.toString()}'),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
