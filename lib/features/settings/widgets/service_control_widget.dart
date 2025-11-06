// lib/features/settings/widgets/service_control_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

import '../../../core/services/app_initialization_service.dart';
import '../../../theme/colors.dart';

/// Widget pour contrôler et afficher l'état des services
class ServiceControlWidget extends StatefulWidget {
  const ServiceControlWidget({super.key});

  @override
  State<ServiceControlWidget> createState() => _ServiceControlWidgetState();
}

class _ServiceControlWidgetState extends State<ServiceControlWidget> {
  bool _isLoading = false;
  Map<String, bool> _serviceStatus = {};

  @override
  void initState() {
    super.initState();
    _checkServiceHealth();
  }

  /// Vérifier l'état de santé des services
  Future<void> _checkServiceHealth() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appInitService = context.read<AppInitializationService>();
      final healthStatus = await appInitService.checkServicesHealth(context);
      
      if (mounted) {
        setState(() {
          _serviceStatus = healthStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Erreur lors de la vérification de l\'état des services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Redémarrer tous les services
  Future<void> _restartServices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appInitService = context.read<AppInitializationService>();
      await appInitService.restartServices(context);
      
      // Vérifier l'état après redémarrage
      await _checkServiceHealth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services redémarrés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Erreur lors du redémarrage des services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du redémarrage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Arrêter tous les services
  Future<void> _stopServices() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appInitService = context.read<AppInitializationService>();
      await appInitService.stopServices(context);
      
      // Vérifier l'état après arrêt
      await _checkServiceHealth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services arrêtés avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      log('Erreur lors de l\'arrêt des services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'arrêt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contrôle des Services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              // État des services
              Text(
                'État des Services',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              ..._serviceStatus.entries.map((entry) => _buildServiceStatusRow(
                _getServiceDisplayName(entry.key),
                entry.value,
              )),
              
              const SizedBox(height: 16),
              
              // Boutons de contrôle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restartServices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Redémarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopServices,
                      icon: const Icon(Icons.stop),
                      label: const Text('Arrêter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkServiceHealth,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Vérifier l\'État'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construire une ligne d'état de service
  Widget _buildServiceStatusRow(String serviceName, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : AppColors.teal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(serviceName),
          ),
          Text(
            isHealthy ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir le nom d'affichage du service
  String _getServiceDisplayName(String serviceKey) {
    switch (serviceKey) {
      case 'geolocation':
        return 'Service de Géolocalisation';
      case 'background_location':
        return 'Localisation en Arrière-plan';
      case 'geofencing':
        return 'Service de Géofencing';
      case 'health_monitor':
        return 'Monitoring de Santé';
      default:
        return serviceKey;
    }
  }
}