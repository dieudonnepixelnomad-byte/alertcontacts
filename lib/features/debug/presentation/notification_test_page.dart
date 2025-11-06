import 'package:flutter/material.dart';
import 'package:alertcontacts/core/services/notification_manager.dart';
import 'package:alertcontacts/theme/app_theme.dart';

/// Page de test pour les notifications et alertes
/// Permet de tester manuellement tous les types de notifications
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final NotificationManager _notificationManager = NotificationManager();
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotificationManager();
  }

  Future<void> _initializeNotificationManager() async {
    setState(() => _isLoading = true);
    
    try {
      final initialized = await _notificationManager.initialize();
      setState(() {
        _isInitialized = initialized;
        _isLoading = false;
      });
      
      if (initialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ NotificationManager initialisé'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Échec initialisation NotificationManager'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testDangerZoneAlert() async {
    if (!_isInitialized) return;
    
    await _notificationManager.triggerDangerZoneAlert(
      zoneName: 'Zone de test - Danger',
      distanceMeters: 150,
      severity: 'high',
    );
    
    _showSuccessSnackBar('Alerte zone de danger déclenchée');
  }

  Future<void> _testSafeZoneAlert() async {
    if (!_isInitialized) return;
    
    await _notificationManager.triggerSafeZoneExitAlert(
      zoneName: 'Maison',
      contactName: 'Marie Dupont',
    );
    
    _showSuccessSnackBar('Alerte sortie zone de sécurité déclenchée');
  }

  Future<void> _testCriticalAlert() async {
    if (!_isInitialized) return;
    
    await _notificationManager.triggerCriticalSystemAlert(
      title: 'Alerte Critique',
      message: 'Test d\'alerte critique système',
    );
    
    _showSuccessSnackBar('Alerte critique déclenchée');
  }

  Future<void> _testSimpleNotification() async {
    if (!_isInitialized) return;
    
    await _notificationManager.sendSimpleNotification(
      title: 'Notification Test',
      body: 'Ceci est une notification de test simple',
    );
    
    _showSuccessSnackBar('Notification simple envoyée');
  }

  Future<void> _testAllSystems() async {
    if (!_isInitialized) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _notificationManager.testAllSystems();
      _showSuccessSnackBar('Test de tous les systèmes terminé');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur test systèmes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final granted = await _notificationManager.requestAllPermissions();
      _showSuccessSnackBar(
        granted ? 'Permissions accordées' : 'Permissions refusées',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: const Color(0xFF006970),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isInitialized ? Icons.check_circle : Icons.error,
                                color: _isInitialized ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isInitialized 
                                    ? 'NotificationManager initialisé'
                                    : 'NotificationManager non initialisé',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _requestPermissions,
                            child: const Text('Demander permissions'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tests individuels
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTestButton(
                          title: 'Test Zone de Danger',
                          subtitle: 'Alerte complète avec vibration et son',
                          icon: Icons.warning,
                          color: Colors.red,
                          onPressed: _isInitialized ? _testDangerZoneAlert : null,
                        ),
                        
                        _buildTestButton(
                          title: 'Test Zone de Sécurité',
                          subtitle: 'Notification de sortie d\'une zone sûre',
                          icon: Icons.shield,
                          color: Colors.green,
                          onPressed: _isInitialized ? _testSafeZoneAlert : null,
                        ),
                        
                        _buildTestButton(
                          title: 'Test Alerte Critique',
                          subtitle: 'Alerte système critique maximale',
                          icon: Icons.emergency,
                          color: Colors.orange,
                          onPressed: _isInitialized ? _testCriticalAlert : null,
                        ),
                        
                        _buildTestButton(
                          title: 'Test Notification Simple',
                          subtitle: 'Notification basique sans alerte',
                          icon: Icons.notifications,
                          color: Colors.blue,
                          onPressed: _isInitialized ? _testSimpleNotification : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTestButton(
                          title: 'Test Complet',
                          subtitle: 'Teste tous les systèmes en séquence',
                          icon: Icons.play_arrow,
                          color: const Color(0xFF006970),
                          onPressed: _isInitialized ? _testAllSystems : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.play_arrow),
        onTap: onPressed,
        enabled: onPressed != null,
      ),
    );
  }
}