import 'package:flutter/material.dart';

import '../../../core/models/gps_tracker.dart';
import '../../../core/services/gps_tracker_service.dart';
import '../../../theme/colors.dart';
import '../../paywall/presentation/paywall_page.dart';

class TraceursTab extends StatefulWidget {
  const TraceursTab({super.key});

  @override
  State<TraceursTab> createState() => _TraceursTabState();
}

class _TraceursTabState extends State<TraceursTab> {
  final _service = GpsTrackerService();
  late Future<GpsTrackerList> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.list();
  }

  void _reload() => setState(() => _future = _service.list());

  Future<void> _add() async {
    try {
      final current = await _future;
      final limit = current.capabilities.trackerLimit;
      if (limit != null && current.trackers.length >= limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('L’offre gratuite est limitée à un traceur GPS.'),
            ),
          );
        }
        return;
      }
    } catch (_) {
      // La création reste possible si la liste n’a pas pu être actualisée.
      // Le serveur applique dans tous les cas la limite définitive.
    }

    if (!mounted) return;

    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _AddTrackerDialog(),
    );

    if (values == null || values.first.trim().isEmpty) return;

    try {
      await _service.create(
        name: values[0].trim(),
        provider: values[1].trim(),
        externalIdentifier: values[2].trim(),
      );
      if (mounted) _reload();
    } on GpsTrackerFreeLimitException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L’offre gratuite est limitée à un traceur GPS.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ajouter ce traceur.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceurs'),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un traceur',
          ),
        ],
      ),
      body: FutureBuilder<GpsTrackerList>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: _reload,
                child: const Text('Réessayer'),
              ),
            );
          }

          final result = snapshot.data!;
          final trackers = result.trackers;
          final capabilities = result.capabilities;

          return Column(
            children: [
              if (!capabilities.isPremium)
                _FreePlanBanner(capabilities: capabilities),
              Expanded(
                child: trackers.isEmpty
                    ? _Empty(onAdd: _add, isPremium: capabilities.isPremium)
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: trackers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) => _TrackerRow(
                            tracker: trackers[index],
                            locationIntervalHours:
                                capabilities.locationIntervalHours,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddTrackerDialog extends StatefulWidget {
  const _AddTrackerDialog();

  @override
  State<_AddTrackerDialog> createState() => _AddTrackerDialogState();
}

class _AddTrackerDialogState extends State<_AddTrackerDialog> {
  final _name = TextEditingController();
  final _provider = TextEditingController();
  final _identifier = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _provider.dispose();
    _identifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un traceur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom du traceur'),
          ),
          TextField(
            controller: _provider,
            decoration: const InputDecoration(
              labelText: 'Fournisseur (facultatif)',
            ),
          ),
          TextField(
            controller: _identifier,
            decoration: const InputDecoration(
              labelText: 'Identifiant matériel (facultatif)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            [_name.text, _provider.text, _identifier.text],
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _FreePlanBanner extends StatelessWidget {
  const _FreePlanBanner({required this.capabilities});

  final TrackerCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offre gratuite',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enregistrez un traceur gratuitement et consultez sa dernière position déjà connue. Le suivi actif, l’historique et les alertes de zone nécessitent Premium.',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaywallPage(
                            trigger: 'gps_trackers',
                          ),
                        ),
                      ),
                      child: const Text('Passer à Premium'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd, required this.isPremium});

  final VoidCallback onAdd;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gps_fixed, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun traceur GPS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                        ? 'Ajoutez un traceur pour suivre sa position et recevoir des alertes de zone.'
                        : 'Ajoutez votre premier traceur GPS gratuitement.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un traceur'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  const _TrackerRow({
    required this.tracker,
    required this.locationIntervalHours,
  });

  final GpsTracker tracker;
  final int? locationIntervalHours;

  @override
  Widget build(BuildContext context) {
    final active = tracker.status == 'active';
    final color = active ? AppColors.success : AppColors.gray600;
    final last = tracker.lastPositionAt;
    final freshness = last == null
        ? 'Aucune position reçue'
        : 'Mise à jour ${_ago(last)}';

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      leading: CircleAvatar(
        backgroundColor: active ? AppColors.primaryLight : AppColors.gray100,
        child: Icon(
          Icons.gps_fixed,
          color: active ? AppColors.primary : AppColors.gray600,
        ),
      ),
      title: Text(tracker.name),
      subtitle: Text(
        locationIntervalHours == 0
            ? freshness
            : '$freshness · Suivi actif réservé à Premium',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            active
                ? 'En ligne'
                : tracker.status == 'draft'
                    ? 'À activer'
                    : 'Hors ligne',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          if (tracker.batteryLevel != null) Text('${tracker.batteryLevel}%'),
        ],
      ),
      onTap: () {},
    );
  }
}

String _ago(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'à l’instant';
  if (difference.inHours < 1) return 'il y a ${difference.inMinutes} min';
  return 'il y a ${difference.inHours} h';
}
