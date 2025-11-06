import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../settings/providers/activities_provider.dart';
import '../models/user_activity.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedActionFilter;
  String? _selectedEntityFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Charger les activités au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesProvider>().loadActivities(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Charger plus d'activités quand on approche de la fin
      context.read<ActivitiesProvider>().loadMoreActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ActivitiesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.activities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.activities.isEmpty) {
            return _ErrorState(
              error: provider.error!,
              onRetry: () => provider.refreshActivities(),
            );
          }

          if (provider.isEmpty) {
            return const _EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Aucune activité',
              subtitle: 'Vos dernières alertes et événements apparaîtront ici.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshActivities(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount:
                  provider.activities.length + (provider.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= provider.activities.length) {
                  // Indicateur de chargement en bas
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final activity = provider.activities[index];
                return _ActivityListTile(activity: activity);
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedAction: _selectedActionFilter,
        selectedEntity: _selectedEntityFilter,
        onApplyFilters: (action, entity) {
          setState(() {
            _selectedActionFilter = action;
            _selectedEntityFilter = entity;
          });

          final provider = context.read<ActivitiesProvider>();
          provider.setActionFilter(action);
          provider.setEntityTypeFilter(entity);
        },
        onClearFilters: () {
          setState(() {
            _selectedActionFilter = null;
            _selectedEntityFilter = null;
          });

          context.read<ActivitiesProvider>().clearFilters();
        },
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  final UserActivity activity;

  const _ActivityListTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActivityColor(activity.action).withOpacity(0.12),
        child: Icon(
          _getActivityIcon(activity.action),
          color: _getActivityColor(activity.action),
        ),
      ),
      title: Text(
        activity.actionDisplayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.locationName != null)
            Text(
              activity.locationName!,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          Text(
            _formatDateTime(activity.createdAt),
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing:
          activity.entityType == 'danger_zone' ||
              activity.entityType == 'safe_zone'
          ? TextButton(
              onPressed: () {
                // TODO: Naviguer vers la carte avec la zone
              },
              child: const Text('Voir'),
            )
          : null,
      onTap: () {
        // TODO: Afficher les détails de l'activité
        _showActivityDetails(context, activity);
      },
    );
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'login':
      case 'register':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'create_danger_zone':
      case 'enter_danger_zone':
        return Colors.red;
      case 'create_safe_zone':
      case 'enter_safe_zone':
        return Colors.blue;
      case 'send_invitation':
      case 'accept_invitation':
        return Colors.purple;
      case 'reject_invitation':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'register':
        return Icons.person_add;
      case 'create_danger_zone':
        return Icons.warning;
      case 'delete_danger_zone':
        return Icons.warning_outlined;
      case 'create_safe_zone':
        return Icons.shield;
      case 'delete_safe_zone':
        return Icons.shield_outlined;
      case 'enter_danger_zone':
        return Icons.dangerous;
      case 'enter_safe_zone':
        return Icons.security;
      case 'send_invitation':
        return Icons.send;
      case 'accept_invitation':
        return Icons.check_circle;
      case 'reject_invitation':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
    }
  }

  void _showActivityDetails(BuildContext context, UserActivity activity) async {
    // Accès libre à l'historique détaillé
    const hasHistoryAccess = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActivityDetailsSheet(
        activity: activity,
        hasHistoryAccess: hasHistoryAccess,
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final String? selectedAction;
  final String? selectedEntity;
  final Function(String?, String?) onApplyFilters;
  final VoidCallback onClearFilters;

  const _FilterDialog({
    required this.selectedAction,
    required this.selectedEntity,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _tempAction;
  String? _tempEntity;

  @override
  void initState() {
    super.initState();
    _tempAction = widget.selectedAction;
    _tempEntity = widget.selectedEntity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer les activités'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type d\'action'),
          const SizedBox(height: 8),
          Consumer<ActivitiesProvider>(
            builder: (context, provider, child) {
              return DropdownButton<String?>(
                value: _tempAction,
                isExpanded: true,
                hint: const Text('Toutes les actions'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes les actions'),
                  ),
                  ...provider.availableActions.map(
                    (action) => DropdownMenuItem<String>(
                      value: action,
                      child: Text(provider.getActionDisplayName(action)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tempAction = value;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Type d\'entité'),
          const SizedBox(height: 8),
          Consumer<ActivitiesProvider>(
            builder: (context, provider, child) {
              return DropdownButton<String?>(
                value: _tempEntity,
                isExpanded: true,
                hint: const Text('Toutes les entités'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes les entités'),
                  ),
                  ...provider.availableEntityTypes.map(
                    (entity) => DropdownMenuItem<String>(
                      value: entity,
                      child: Text(provider.getEntityTypeDisplayName(entity)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tempEntity = value;
                  });
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onClearFilters();
            Navigator.of(context).pop();
          },
          child: const Text('Effacer'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilters(_tempAction, _tempEntity);
            Navigator.of(context).pop();
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

class _ActivityDetailsSheet extends StatelessWidget {
  final UserActivity activity;
  final bool hasHistoryAccess;

  const _ActivityDetailsSheet({
    required this.activity,
    required this.hasHistoryAccess,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Détails de l\'activité',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (!hasHistoryAccess)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Informations de base (toujours visibles)
                    _DetailRow('Action', activity.actionDisplayName),
                    _DetailRow('Type', activity.entityTypeDisplayName),
                    _DetailRow(
                      'Date',
                      DateFormat(
                        'dd/MM/yyyy à HH:mm',
                      ).format(activity.createdAt),
                    ),

                    if (hasHistoryAccess) ...[
                      // Informations détaillées (premium uniquement)
                      if (activity.ipAddress != null)
                        _DetailRow('Adresse IP', activity.ipAddress!),
                      if (activity.userAgent != null)
                        _DetailRow('Navigateur', activity.userAgent!),
                      if (activity.metadata != null &&
                          activity.metadata!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Informations supplémentaires',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...activity.metadata!.entries.map(
                          (entry) =>
                              _DetailRow(entry.key, entry.value.toString()),
                        ),
                      ],
                    ] else ...[
                      // Message pour les utilisateurs non-premium
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Historique détaillé',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Accédez aux informations techniques détaillées (adresse IP, navigateur, métadonnées) avec AlertContact Premium.',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // TODO: Naviguer vers la page d'abonnement
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Découvrir Premium'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 10),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
