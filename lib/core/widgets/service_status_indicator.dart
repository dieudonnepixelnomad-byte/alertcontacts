import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/persistent_status_notification_service.dart';

/// Widget d'indicateur de statut des services de surveillance
/// Affiche un indicateur visuel discret de l'état des services actifs
class ServiceStatusIndicator extends StatefulWidget {
  const ServiceStatusIndicator({super.key});

  @override
  State<ServiceStatusIndicator> createState() => _ServiceStatusIndicatorState();
}

class _ServiceStatusIndicatorState extends State<ServiceStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersistentStatusNotificationService>(
      builder: (context, statusService, child) {
        final hasActiveServices = statusService.hasActiveServices;
        
        if (!hasActiveServices) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(statusService),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(statusService).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(PersistentStatusNotificationService statusService) {
    final geolocationActive = statusService.geolocationStatus == ServiceStatus.running;
    final backgroundLocationActive = statusService.backgroundLocationStatus == ServiceStatus.running;

    if (geolocationActive && backgroundLocationActive) {
      return Colors.green; // Tous les services actifs
    } else if (geolocationActive || backgroundLocationActive) {
      return Colors.orange; // Certains services actifs
    } else {
      return Colors.red; // Aucun service actif
    }
  }
}

/// Widget d'indicateur de statut détaillé pour les paramètres
class DetailedServiceStatusWidget extends StatelessWidget {
  const DetailedServiceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersistentStatusNotificationService>(
      builder: (context, statusService, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'État des services de surveillance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildServiceStatusRow(
                  'Géolocalisation',
                  statusService.geolocationStatus,
                  Icons.location_on,
                ),
                const SizedBox(height: 8),
                _buildServiceStatusRow(
                  'Localisation en arrière-plan',
                  statusService.backgroundLocationStatus,
                  Icons.my_location,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dernière mise à jour: ${_formatLastUpdate(statusService.lastUpdate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceStatusRow(String serviceName, ServiceStatus status, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _getStatusColor(status)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(serviceName),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return Colors.green;
      case ServiceStatus.stopped:
        return Colors.red;
      case ServiceStatus.error:
        return Colors.orange;
      case ServiceStatus.starting:
        return Colors.grey;
    }
  }

  String _getStatusText(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return 'Actif';
      case ServiceStatus.stopped:
        return 'Arrêté';
      case ServiceStatus.error:
        return 'Erreur';
      case ServiceStatus.starting:
        return 'Démarrage';
    }
  }

  String _formatLastUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}