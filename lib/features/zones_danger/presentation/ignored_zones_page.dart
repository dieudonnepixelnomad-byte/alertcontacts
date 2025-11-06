import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/ignored_danger_zone.dart';
import '../../../theme/colors.dart';
import '../providers/ignored_danger_zones_provider.dart';
import 'widgets/ignored_zone_card.dart';

class IgnoredZonesPage extends StatefulWidget {
  const IgnoredZonesPage({super.key});

  @override
  State<IgnoredZonesPage> createState() => _IgnoredZonesPageState();
}

class _IgnoredZonesPageState extends State<IgnoredZonesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showExpired = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger les zones ignorées au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IgnoredDangerZonesProvider>().loadIgnoredZones();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Zones ignorées',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<IgnoredDangerZonesProvider>().refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.visibility_off),
              text: 'Actives',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Expirées',
            ),
          ],
        ),
      ),
      body: Consumer<IgnoredDangerZonesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!, provider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveZonesList(provider.activeIgnoredZones, provider),
              _buildExpiredZonesList(provider.expiredIgnoredZones, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, IgnoredDangerZonesProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveZonesList(
    List<IgnoredDangerZone> zones,
    IgnoredDangerZonesProvider provider,
  ) {
    if (zones.isEmpty) {
      return _buildEmptyState(
        icon: Icons.visibility_off_outlined,
        title: 'Aucune zone ignorée',
        subtitle: 'Vous n\'avez ignoré aucune zone de danger pour le moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          return IgnoredZoneCard(
            ignoredZone: zone,
            onReactivate: () => _handleReactivate(zone, provider),
            onExtend: () => _handleExtend(zone, provider),
          );
        },
      ),
    );
  }

  Widget _buildExpiredZonesList(
    List<IgnoredDangerZone> zones,
    IgnoredDangerZonesProvider provider,
  ) {
    if (zones.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_outlined,
        title: 'Aucune zone expirée',
        subtitle: 'Aucune zone ignorée n\'a encore expiré.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          return IgnoredZoneCard(
            ignoredZone: zone,
            isExpired: true,
            onReactivate: () => _handleReactivate(zone, provider),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReactivate(
    IgnoredDangerZone zone,
    IgnoredDangerZonesProvider provider,
  ) async {
    final confirmed = await _showReactivateDialog(zone);
    if (!confirmed) return;

    final success = await provider.reactivateDangerZone(zone.dangerZoneId);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alertes réactivées pour "${zone.dangerZone?.title ?? 'Zone'}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la réactivation'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleExtend(
    IgnoredDangerZone zone,
    IgnoredDangerZonesProvider provider,
  ) async {
    final confirmed = await _showExtendDialog(zone);
    if (!confirmed) return;

    final success = await provider.extendIgnoredZone(zone.dangerZoneId);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durée prolongée pour "${zone.dangerZone?.title ?? 'Zone'}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la prolongation'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _showReactivateDialog(IgnoredDangerZone zone) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réactiver les alertes'),
        content: Text(
          'Voulez-vous réactiver les alertes pour la zone "${zone.dangerZone?.title ?? 'Zone'}" ?\n\n'
          'Vous recevrez à nouveau des notifications lorsque vous vous approcherez de cette zone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réactiver'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showExtendDialog(IgnoredDangerZone zone) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prolonger l\'ignorage'),
        content: Text(
          'Voulez-vous prolonger l\'ignorage de la zone "${zone.dangerZone?.title ?? 'Zone'}" ?\n\n'
          'La durée sera prolongée de 6 mois supplémentaires.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Prolonger'),
          ),
        ],
      ),
    ) ?? false;
  }
}