import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../alertes/services/notification_config_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _configService = NotificationConfigService();

  // Variables d'état pour les paramètres
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _voiceAlertsEnabled = true;
  bool _quietHoursEnabled = false;
  bool _discreteMode = false;
  int _quietHoursStart = 22;
  int _quietHoursEnd = 7;
  // Cooldown supprimé - géré côté backend
  double _warningDistance = 100.0;
  double _criticalDistance = 50.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadSettings();
  }

  Future<void> _initializeAndLoadSettings() async {
    try {
      // Initialiser le service d'abord
      await _configService.initialize();

      // Puis charger les paramètres
      await _loadSettings();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des paramètres: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _notificationsEnabled = _configService.notificationsEnabled;
      _vibrationEnabled = _configService.vibrationEnabled;
      _voiceAlertsEnabled = _configService.voiceAlertsEnabled;
      _quietHoursEnabled = _configService.quietHoursEnabled;
      _discreteMode = _configService.discreteMode;
      _quietHoursStart = _configService.quietHoursStart;
      _quietHoursEnd = _configService.quietHoursEnd;
      // Cooldown supprimé - géré côté backend
      _warningDistance = _configService.warningDistance;
      _criticalDistance = _configService.criticalDistance;
    });
  }

  // Méthodes de sauvegarde automatique pour chaque paramètre
  Future<void> _updateNotificationsEnabled(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _configService.setNotificationsEnabled(value);
    _showAutoSaveMessage();
  }

  Future<void> _updateVibrationEnabled(bool value) async {
    setState(() {
      _vibrationEnabled = value;
    });
    await _configService.setVibrationEnabled(value);
    _showAutoSaveMessage();
  }

  Future<void> _updateVoiceAlertsEnabled(bool value) async {
    setState(() {
      _voiceAlertsEnabled = value;
    });
    await _configService.setVoiceAlertsEnabled(value);
    _showAutoSaveMessage();
  }

  Future<void> _updateQuietHoursEnabled(bool value) async {
    setState(() {
      _quietHoursEnabled = value;
    });
    await _configService.setQuietHoursEnabled(value);
    _showAutoSaveMessage();
  }

  Future<void> _updateDiscreteMode(bool value) async {
    setState(() {
      _discreteMode = value;
    });
    await _configService.setDiscreteMode(value);
    _showAutoSaveMessage();
  }

  // Méthode _updateNotificationCooldown supprimée - géré côté backend

  Future<void> _updateWarningDistance(double value) async {
    setState(() {
      _warningDistance = value;
    });
    await _configService.setWarningDistance(value);
    _showAutoSaveMessage();
  }

  Future<void> _updateCriticalDistance(double value) async {
    setState(() {
      _criticalDistance = value;
    });
    await _configService.setCriticalDistance(value);
    _showAutoSaveMessage();
  }

  void _showAutoSaveMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Sauvegardé automatiquement'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    await _configService.setNotificationsEnabled(_notificationsEnabled);
    await _configService.setVibrationEnabled(_vibrationEnabled);
    await _configService.setVoiceAlertsEnabled(_voiceAlertsEnabled);
    await _configService.setQuietHoursEnabled(_quietHoursEnabled);
    await _configService.setDiscreteMode(_discreteMode);
    await _configService.setQuietHoursStart(_quietHoursStart);
    await _configService.setQuietHoursEnd(_quietHoursEnd);
    // Cooldown supprimé - géré côté backend
    await _configService.setWarningDistance(_warningDistance);
    await _configService.setCriticalDistance(_criticalDistance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les paramètres sauvegardés'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    await _configService.resetToDefaults();
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres réinitialisés'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isStart ? _quietHoursStart : _quietHoursEnd,
        minute: 0,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = picked.hour;
        } else {
          _quietHoursEnd = picked.hour;
        }
      });

      // Sauvegarder automatiquement
      if (isStart) {
        await _configService.setQuietHoursStart(picked.hour);
      } else {
        await _configService.setQuietHoursEnd(picked.hour);
      }
      _showAutoSaveMessage();
    }
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des paramètres...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Notifications générales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications générales',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          key: const Key('notifications_enabled_switch'),
                          title: const Text('Activer les notifications'),
                          subtitle: const Text(
                            'Recevoir des alertes de sécurité',
                          ),
                          value: _notificationsEnabled,
                          onChanged: _updateNotificationsEnabled,
                        ),
                        SwitchListTile(
                          key: const Key('vibration_enabled_switch'),
                          title: const Text('Vibrations'),
                          subtitle: const Text('Vibrer lors des alertes'),
                          value: _vibrationEnabled,
                          onChanged: _notificationsEnabled
                              ? _updateVibrationEnabled
                              : null,
                        ),
                        SwitchListTile(
                          key: const Key('voice_alerts_enabled_switch'),
                          title: const Text('Alertes vocales'),
                          subtitle: const Text(
                            'Annonces vocales pour les alertes critiques',
                          ),
                          value: _voiceAlertsEnabled,
                          onChanged: _notificationsEnabled
                              ? _updateVoiceAlertsEnabled
                              : null,
                        ),
                        SwitchListTile(
                          key: const Key('discrete_mode_switch'),
                          title: const Text('Mode discret'),
                          subtitle: const Text(
                            'Vibrations uniquement, sans son',
                          ),
                          value: _discreteMode,
                          onChanged: _notificationsEnabled
                              ? _updateDiscreteMode
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Heures calmes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heures calmes',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pendant les heures calmes, seules les notifications discrètes sont envoyées',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          key: const Key('quiet_hours_enabled_switch'),
                          title: const Text('Activer les heures calmes'),
                          value: _quietHoursEnabled,
                          onChanged: _notificationsEnabled
                              ? _updateQuietHoursEnabled
                              : null,
                        ),
                        if (_quietHoursEnabled) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Début'),
                                  subtitle: Text(_formatHour(_quietHoursStart)),
                                  trailing: const Icon(Icons.access_time),
                                  onTap: () => _selectTime(true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ListTile(
                                  title: const Text('Fin'),
                                  subtitle: Text(_formatHour(_quietHoursEnd)),
                                  trailing: const Icon(Icons.access_time),
                                  onTap: () => _selectTime(false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _configService.isInQuietHours
                                      ? Icons.bedtime
                                      : Icons.wb_sunny,
                                  color: _configService.isInQuietHours
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _configService.isInQuietHours
                                      ? 'Actuellement en heures calmes'
                                      : 'Heures calmes inactives',
                                  style: TextStyle(
                                    color: _configService.isInQuietHours
                                        ? Colors.blue
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Distances et cooldown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paramètres avancés',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        // Interface cooldown supprimée - géré côté backend
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Distance d\'avertissement'),
                          subtitle: Text('${_warningDistance.round()} mètres'),
                          trailing: const Icon(Icons.warning),
                        ),
                        Slider(
                          value: _warningDistance,
                          min: 50,
                          max: 500,
                          divisions: 18,
                          label: '${_warningDistance.round()} m',
                          onChanged: _updateWarningDistance,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Distance critique'),
                          subtitle: Text('${_criticalDistance.round()} mètres'),
                          trailing: const Icon(Icons.dangerous),
                        ),
                        Slider(
                          value: _criticalDistance,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          label: '${_criticalDistance.round()} m',
                          onChanged: _updateCriticalDistance,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Information sur la sauvegarde automatique
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Les paramètres sont sauvegardés automatiquement à chaque modification',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton de sauvegarde manuelle (optionnel)
                OutlinedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Forcer la sauvegarde complète'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
