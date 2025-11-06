// lib/features/settings/widgets/system_reliability_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/unified_critical_alert_service.dart';
import '../../../core/services/proactive_system_monitor.dart';

/// Widget de dashboard pour surveiller la fiabilité du système d'alertes
class SystemReliabilityDashboard extends StatefulWidget {
  const SystemReliabilityDashboard({Key? key}) : super(key: key);

  @override
  State<SystemReliabilityDashboard> createState() => _SystemReliabilityDashboardState();
}

class _SystemReliabilityDashboardState extends State<SystemReliabilityDashboard> {
  final UnifiedCriticalAlertService _alertService = UnifiedCriticalAlertService();
  Timer? _refreshTimer;
  
  AlertReliabilityReport? _currentReport;
  Map<String, dynamic> _systemStats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    // Configurer les callbacks
    _alertService.onReliabilityReport = (report) {
      if (mounted) {
        setState(() {
          _currentReport = report;
        });
      }
    };

    // Charger les données initiales
    await _refreshData();
    
    // Démarrer le rafraîchissement automatique
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      final stats = _alertService.getComprehensiveStatistics();
      
      if (mounted) {
        setState(() {
          _systemStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildReliabilityOverview(),
              const SizedBox(height: 16),
              _buildSystemStatus(),
              const SizedBox(height: 16),
              _buildStatistics(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.security,
          color: Color(0xFF006970),
          size: 28,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Fiabilité du Système de Sécurité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006970),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildReliabilityOverview() {
    final unifiedStats = _systemStats['unified_service'] as Map<String, dynamic>?;
    if (unifiedStats == null) return const SizedBox.shrink();

    final reliabilityRate = (unifiedStats['reliability_rate'] as double?) ?? 0.0;
    final isEmergencyMode = unifiedStats['is_emergency_mode'] as bool? ?? false;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isEmergencyMode) {
      statusColor = Colors.red;
      statusText = 'MODE D\'URGENCE';
      statusIcon = Icons.warning;
    } else if (reliabilityRate >= 0.95) {
      statusColor = Colors.green;
      statusText = 'OPTIMAL';
      statusIcon = Icons.check_circle;
    } else if (reliabilityRate >= 0.85) {
      statusColor = Colors.orange;
      statusText = 'DÉGRADÉ';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = 'CRITIQUE';
      statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Fiabilité: ${(reliabilityRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: reliabilityRate,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    final monitorStats = _systemStats['system_monitor'] as Map<String, dynamic>?;
    if (monitorStats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'État des Composants',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildComponentStatus('Batterie', _getBatteryStatus()),
        _buildComponentStatus('Connectivité', _getConnectivityStatus()),
        _buildComponentStatus('Permissions', _getPermissionsStatus()),
        _buildComponentStatus('Backend', _getBackendStatus()),
      ],
    );
  }

  Widget _buildComponentStatus(String component, ComponentStatus status) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.level) {
      case StatusLevel.ok:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case StatusLevel.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case StatusLevel.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              component,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            status.message,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final unifiedStats = _systemStats['unified_service'] as Map<String, dynamic>?;
    if (unifiedStats == null) return const SizedBox.shrink();

    final totalGenerated = unifiedStats['total_generated'] as int? ?? 0;
    final totalDelivered = unifiedStats['total_delivered'] as int? ?? 0;
    final totalAcknowledged = unifiedStats['total_acknowledged'] as int? ?? 0;
    final consecutiveFailures = unifiedStats['consecutive_failures'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Alertes Générées',
                totalGenerated.toString(),
                Icons.notification_add,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Alertes Livrées',
                totalDelivered.toString(),
                Icons.done,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Accusés Réception',
                totalAcknowledged.toString(),
                Icons.verified,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Échecs Consécutifs',
                consecutiveFailures.toString(),
                Icons.error_outline,
                consecutiveFailures > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _testCriticalAlert,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test Alerte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006970),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showDetailedReport,
            icon: const Icon(Icons.analytics),
            label: const Text('Rapport Détaillé'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF006970),
            ),
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires pour obtenir le statut des composants
  ComponentStatus _getBatteryStatus() {
    // TODO: Implémenter la vérification réelle de la batterie
    return ComponentStatus(StatusLevel.ok, 'OK');
  }

  ComponentStatus _getConnectivityStatus() {
    // TODO: Implémenter la vérification réelle de la connectivité
    return ComponentStatus(StatusLevel.ok, 'Connecté');
  }

  ComponentStatus _getPermissionsStatus() {
    // TODO: Implémenter la vérification réelle des permissions
    return ComponentStatus(StatusLevel.ok, 'Accordées');
  }

  ComponentStatus _getBackendStatus() {
    // TODO: Implémenter la vérification réelle du backend
    return ComponentStatus(StatusLevel.ok, 'Opérationnel');
  }

  Future<void> _testCriticalAlert() async {
    try {
      await _alertService.sendCriticalAlert(
        alertId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test d\'Alerte Critique',
        message: 'Ceci est un test du système d\'alertes critiques.',
        type: CriticalAlertType.systemFailure,
        priority: AlertPriority.high,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test d\'alerte envoyé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailedReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport Détaillé'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Statistiques Complètes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_formatDetailedStats()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDetailedStats() {
    return _systemStats.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}

/// Statut d'un composant système
class ComponentStatus {
  final StatusLevel level;
  final String message;

  ComponentStatus(this.level, this.message);
}

/// Niveau de statut
enum StatusLevel {
  ok,
  warning,
  error,
}