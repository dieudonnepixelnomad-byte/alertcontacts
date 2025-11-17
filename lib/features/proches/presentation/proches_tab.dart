// lib/features/proches/presentation/proches_tab.dart
import 'dart:developer';
import 'package:alertcontacts/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/models/invitation.dart';
import '../providers/relationship_provider.dart';
import 'assign_zones_page.dart';
import 'contact_locations_page.dart';

class ProchesTab extends StatefulWidget {
  const ProchesTab({super.key});
  @override
  State<ProchesTab> createState() => _ProchesTabState();
}

class _ProchesTabState extends State<ProchesTab> {
  @override
  void initState() {
    super.initState();
    // Initialiser l'authentification puis charger les relations
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final relationshipProvider = context.read<RelationshipProvider>();
      await relationshipProvider.initialize();
      await relationshipProvider.loadRelationships();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _invite,
        icon: const Icon(Icons.person_add),
        label: const Text('Inviter'),
      ),
      body: Consumer<RelationshipProvider>(
        builder: (context, relationshipProvider, child) {
          if (relationshipProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (relationshipProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    relationshipProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => relationshipProvider.loadRelationships(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final acceptedRelationships =
              relationshipProvider.acceptedRelationships;

          if (acceptedRelationships.isEmpty) {
            return _EmptyState(
              icon: Icons.group_outlined,
              title: 'Aucun proche',
              subtitle:
                  'Invitez un proche pour partager des alertes et des zones.\n\nUtilisez le bouton "Inviter" pour commencer.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => relationshipProvider.refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemBuilder: (_, i) => _ProcheTile(
                contactRelation: acceptedRelationships[i],
                onLevelChanged: (shareLevel) =>
                    _updateShareLevel(acceptedRelationships[i].id, shareLevel),
                onRemove: () => _remove(acceptedRelationships[i]),
                onManageZones: () => _manageZones(acceptedRelationships[i]),
                onViewLocations: () => _viewLocations(acceptedRelationships[i]),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: acceptedRelationships.length,
            ),
          );
        },
      ),
    );
  }

  void _invite() {
    context.push(AppRoutes.addProche);
  }

  Future<void> _updateShareLevel(
    String relationshipId,
    ShareLevel shareLevel,
  ) async {
    final relationshipProvider = context.read<RelationshipProvider>();
    // Log des paramètres reçus par la méthode
    log('UI: Tentative de mise à jour du niveau de partage. RelationshipId: $relationshipId, ShareLevel: $shareLevel');

    final success = await relationshipProvider.updateShareLevel(
      relationshipId,
      shareLevel,
    );

    if (!success && mounted) {
      // Log de l'échec
      log('UI: Echec de la mise à jour du niveau de partage. Erreur: ${relationshipProvider.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            relationshipProvider.error ?? 'Erreur lors de la mise à jour',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _manageZones(ContactRelation contactRelation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignZonesPage(contactRelation: contactRelation),
      ),
    );
  }

  void _viewLocations(ContactRelation contactRelation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ContactLocationsPage(contactRelation: contactRelation),
      ),
    );
  }

  void _remove(ContactRelation contactRelation) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer ce proche ?'),
        content: Text(
          'Vous ne partagerez plus vos informations avec ${contactRelation.contact.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final relationshipProvider = context.read<RelationshipProvider>();
      final success = await relationshipProvider.deleteRelationship(
        contactRelation.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Proche retiré')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                relationshipProvider.error ?? 'Erreur lors de la suppression',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _ProcheTile extends StatelessWidget {
  final ContactRelation contactRelation;
  final ValueChanged<ShareLevel> onLevelChanged;
  final VoidCallback onRemove;
  final VoidCallback onManageZones;
  final VoidCallback onViewLocations;
  const _ProcheTile({
    required this.contactRelation,
    required this.onLevelChanged,
    required this.onRemove,
    required this.onManageZones,
    required this.onViewLocations,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String label(ShareLevel l) => switch (l) {
      ShareLevel.realtime => 'Temps réel',
      ShareLevel.alertOnly => 'Uniquement alertes',
      ShareLevel.none => 'Aucun',
    };

    IconData icon(ShareLevel l) => switch (l) {
      ShareLevel.realtime => Icons.radio_button_checked,
      ShareLevel.alertOnly => Icons.notifications_active_outlined,
      ShareLevel.none => Icons.block,
    };

    Color color(ShareLevel l) => switch (l) {
      ShareLevel.realtime => const Color(0xFF2E7D32),
      ShareLevel.alertOnly => const Color(0xFF006970),
      ShareLevel.none => cs.error,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withOpacity(.12),
            backgroundImage: NetworkImage(contactRelation.contact.avatarUrl),
            child: null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactRelation.contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      icon(contactRelation.shareLevel),
                      size: 16,
                      color: color(contactRelation.shareLevel),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label(contactRelation.shareLevel),
                      style: TextStyle(color: cs.onSurface.withOpacity(.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'manage_zones') {
                onManageZones();
              } else if (value == 'view_locations') {
                onViewLocations();
              } else {
                // Gestion des niveaux de partage
                final shareLevel = ShareLevel.values.firstWhere(
                  (level) => level.toString() == value,
                );
                onLevelChanged(shareLevel);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'manage_zones',
                child: Row(
                  children: const [
                    Icon(Icons.location_on, size: 18),
                    SizedBox(width: 8),
                    Text('Gérer les zones'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'view_locations',
                child: Row(
                  children: const [
                    Icon(Icons.timeline, size: 18),
                    SizedBox(width: 8),
                    Text('Voir les positions'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: ShareLevel.realtime.toString(),
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 18,
                      color: contactRelation.shareLevel == ShareLevel.realtime
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    const Text('Temps réel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShareLevel.alertOnly.toString(),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 18,
                      color: contactRelation.shareLevel == ShareLevel.alertOnly
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    const Text('Uniquement alertes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ShareLevel.none.toString(),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 18,
                      color: contactRelation.shareLevel == ShareLevel.none
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    const Text('Aucun'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? cta;
  final VoidCallback? onCta;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.onCta,
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
            if (cta != null && onCta != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onCta, child: Text(cta!)),
            ],
          ],
        ),
      ),
    );
  }
}
