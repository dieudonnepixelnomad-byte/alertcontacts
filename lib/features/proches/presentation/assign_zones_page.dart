// lib/features/proches/presentation/assign_zones_page.dart
import 'package:flutter/material.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/services/api_relationship_service.dart' as api_service;
import '../../../core/services/prefs_service.dart';
import '../../../core/errors/auth_exceptions.dart';

import '../../../theme/colors.dart';

class AssignZonesPage extends StatefulWidget {
  final ContactRelation contactRelation;

  const AssignZonesPage({super.key, required this.contactRelation});

  @override
  State<AssignZonesPage> createState() => _AssignZonesPageState();
}

class _AssignZonesPageState extends State<AssignZonesPage> {
  final api_service.ApiRelationshipService _relationshipService =
      api_service.ApiRelationshipService();
  final PrefsService _prefsService = PrefsService();

  List<api_service.AssignableZone> _zones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _ensureAuthenticated();
      final zones = await _relationshipService.getAssignableZones(
        widget.contactRelation.contact.id,
      );

      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ensureAuthenticated() async {
    final token = await _prefsService.getBearerToken();
    if (token == null) {
      throw const InvalidCredentialsException();
    }
    _relationshipService.setAuthToken(token);
  }

  Future<void> _toggleZoneAssignment(api_service.AssignableZone zone) async {
    try {
      await _ensureAuthenticated();

      if (zone.isAssigned) {
        // Retirer l'assignation - pas de vérification nécessaire
        await _relationshipService.unassignZone(
          widget.contactRelation.contact.id,
          zone.id,
        );
      } else {
        // Assigner la zone - l'API backend vérifiera les restrictions d'abonnement
        await _relationshipService.assignZone(
          widget.contactRelation.contact.id,
          zone.id,
        );
      }

      // Recharger les zones pour mettre à jour l'état
      await _loadZones();

      if (mounted) {
        final action = zone.isAssigned ? 'retirée' : 'assignée';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone "${zone.name}" $action avec succès'),
            backgroundColor: AppColors.safe,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Vérifier si c'est une erreur de restriction d'abonnement
        final errorMessage = e.toString();
        if (errorMessage.contains('SUBSCRIPTION_LIMIT_REACHED') ||
            errorMessage.contains('Limite atteinte') ||
            errorMessage.contains('mode gratuit')) {
          // Afficher un message d'information simple
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Fonctionnalité disponible sans restriction'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          // Afficher l'erreur normale
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleZoneStatus(api_service.AssignableZone zone) async {
    if (!zone.isAssigned) return;

    try {
      await _ensureAuthenticated();

      final newStatus = zone.assignmentStatus == 'active' ? 'paused' : 'active';
      await _relationshipService.toggleZoneAssignment(
        widget.contactRelation.contact.id,
        zone.id,
        newStatus,
      );

      // Recharger les zones pour mettre à jour l'état
      await _loadZones();

      if (mounted) {
        final action = newStatus == 'active' ? 'activée' : 'mise en pause';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone "${zone.name}" $action'),
            backgroundColor: AppColors.safe,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la modification du statut';

        // Gestion spécifique des types d'erreurs
        if (e is api_service.ValidationException) {
          errorMessage = 'Données invalides: ${e.message}';
        } else if (e is api_service.RelationshipNotFoundException) {
          errorMessage = 'Contact ou zone non trouvé';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Délai d\'attente dépassé, vérifiez votre connexion';
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Problème de connexion réseau';
        } else {
          // Extraire le message d'erreur s'il est disponible
          final errorStr = e.toString();
          if (errorStr.contains('Exception:')) {
            errorMessage = errorStr.split('Exception:').last.trim();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Zones de ${widget.contactRelation.contact.name}'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des zones...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadZones, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_zones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: cs.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune zone de sécurité',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez d\'abord des zones de sécurité pour pouvoir les assigner à vos proches.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadZones,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _zones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final zone = _zones[index];
          return _ZoneCard(
            zone: zone,
            onToggleAssignment: () => _toggleZoneAssignment(zone),
            onToggleStatus: () => _toggleZoneStatus(zone),
          );
        },
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final api_service.AssignableZone zone;
  final VoidCallback onToggleAssignment;
  final VoidCallback onToggleStatus;

  const _ZoneCard({
    required this.zone,
    required this.onToggleAssignment,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isActive = zone.isAssigned && zone.assignmentStatus == 'active';
    final isPaused = zone.isAssigned && zone.assignmentStatus == 'paused';

    Color cardColor = cs.surface;
    Color borderColor = cs.outlineVariant;

    if (isActive) {
      cardColor = AppColors.safe.withOpacity(0.1);
      borderColor = AppColors.safe.withOpacity(0.3);
    } else if (isPaused) {
      cardColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getZoneIcon(zone.icon),
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rayon: ${zone.radiusM}m',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleAssignment,
                  icon: Icon(
                    zone.isAssigned
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(zone.isAssigned ? 'Retirer' : 'Assigner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: zone.isAssigned ? cs.error : cs.primary,
                    side: BorderSide(
                      color: zone.isAssigned ? cs.error : cs.primary,
                    ),
                  ),
                ),
              ),
              if (zone.isAssigned) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(isActive ? 'Pause' : 'Activer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.orange
                          : AppColors.safe,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!zone.isAssigned) {
      return Chip(
        label: const Text('Non assignée'),
        backgroundColor: cs.surfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      );
    }

    final isActive = zone.assignmentStatus == 'active';
    return Chip(
      label: Text(isActive ? 'Active' : 'En pause'),
      backgroundColor: isActive ? AppColors.safe : Colors.orange,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _getZoneIcon(String iconKey) {
    switch (iconKey) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'hospital':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'gym':
        return Icons.fitness_center;
      case 'park':
        return Icons.park;
      default:
        return Icons.location_on;
    }
  }
}
