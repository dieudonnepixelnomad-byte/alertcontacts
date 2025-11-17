// lib/features/proches/presentation/invite_proche_page.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/safe_zone.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/api_safezone_service.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/errors/auth_exceptions.dart';

import '../../../core/config/api_config.dart';

// Utilisation du ShareLevel depuis le modèle Invitation
// enum ShareLevel { realtime, alertOnly, none } - maintenant importé

class InviteProchePage extends StatefulWidget {
  const InviteProchePage({super.key});
  @override
  State<InviteProchePage> createState() => _InviteProchePageState();
}

class _InviteProchePageState extends State<InviteProchePage> {
  late final ApiSafeZoneService _safeZoneService;
  late final ApiInvitationService _invitationService;
  late final PrefsService _prefsService;

  // Réglages
  ShareLevel _level = ShareLevel.alertOnly;
  bool _theySeeMe = true;
  List<SafeZone> _availableZones = [];
  Map<String, bool> _selectedZones = {};
  Duration _expiry = const Duration(hours: 1);
  int _maxUses = 1;
  String? _pin; // optionnel

  // États de chargement
  bool _isLoadingZones = true;
  bool _isGeneratingInvitation = false;
  String? _errorMessage;

  // Résultats générés (RÉELS)
  Invitation? _generatedInvitation;
  String? _inviteUrl;

  @override
  void initState() {
    super.initState();
    _safeZoneService = Provider.of<ApiSafeZoneService>(context, listen: false);
    _invitationService = Provider.of<ApiInvitationService>(
      context,
      listen: false,
    );
    _prefsService = Provider.of<PrefsService>(context, listen: false);
    _initializeAuthentication();
    _loadSafeZones();
  }

  /// Initialiser l'authentification pour les services API
  Future<void> _initializeAuthentication() async {
    try {
      final token = await _prefsService.getBearerToken();
      if (token != null) {
        _safeZoneService.setBearerToken(token);
        _invitationService.setAuthToken(token);
        log('Authentication initialized with token');
      } else {
        log('No authentication token found');
      }
    } catch (e) {
      log('Error initializing authentication: $e');
    }
  }

  /// S'assurer que l'utilisateur est authentifié avant les appels API
  Future<void> _ensureAuthenticated() async {
    final token = await _prefsService.getBearerToken();
    if (token == null) {
      throw const InvalidCredentialsException();
    }
    _safeZoneService.setBearerToken(token);
    _invitationService.setAuthToken(token);
  }

  Future<void> _loadSafeZones() async {
    try {
      setState(() {
        _isLoadingZones = true;
        _errorMessage = null;
      });

      // S'assurer que l'authentification est à jour
      await _ensureAuthenticated();

      final zones = await _safeZoneService.getSafeZones();
      setState(() {
        _availableZones = zones;
        _selectedZones = {for (var zone in zones) zone.id: false};
        _isLoadingZones = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingZones = false;
        _errorMessage = 'Erreur lors du chargement des zones: $e';
      });
    }
  }

  Future<void> _generate() async {
    if (_isGeneratingInvitation) return;

    try {
      setState(() {
        _isGeneratingInvitation = true;
        _errorMessage = null;
      });

      // S'assurer que l'authentification est à jour
      await _ensureAuthenticated();

      // Récupérer les IDs des zones sélectionnées
      final selectedZoneIds = _selectedZones.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      log('Zones sélectionnées: $selectedZoneIds');

      // Calculer les heures d'expiration
      final expiresInHours = _expiry.inHours;
      log('Heures d\'expiration: $expiresInHours');

      // Créer l'invitation via l'API
      final invitation = await _invitationService.createInvitation(
        defaultShareLevel: _level,
        suggestedZones: selectedZoneIds,
        expiresInHours: expiresInHours,
        maxUses: _maxUses == 9999 ? null : _maxUses,
        requirePin: (_pin != null && _pin!.length == 4),
        message: null,
      );

      log('Invitation Response: $invitation');

      // Générer l'URL d'invitation via le backend Laravel
      _inviteUrl = ApiConfig.getInvitationUrl(invitation.token);

      log('URL d\'invitation: $_inviteUrl');

      setState(() {
        _generatedInvitation = invitation;
        _isGeneratingInvitation = false;
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isGeneratingInvitation = false;
        _errorMessage = 'Erreur lors de la création de l\'invitation: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  /// Afficher une boîte de dialogue de succès attrayante
  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Invitation créée',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Le lien est prêt à être partagé. Scrollez vers le bas pour pouvoir partager le lien à votre proche.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Construire le message de partage pour l'invitation
  String _buildShareMessage() {
    final invitation = _generatedInvitation!;
    final expiryDate = invitation.expiresAt;
    final formattedDate =
        '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    final formattedTime =
        '${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}';

    String message = '🔗 Invitation AlertContact\n\n';
    message +=
        'Vous êtes invité(e) à rejoindre mon réseau de sécurité AlertContact.\n\n';

    if (invitation.message != null && invitation.message!.isNotEmpty) {
      message += '💬 Message: ${invitation.message}\n\n';
    }

    message += '📅 Valide jusqu\'au $formattedDate à $formattedTime\n';
    message +=
        '🔢 Utilisations: ${invitation.maxUses == 1 ? "1 seule utilisation" : "${invitation.maxUses} utilisations"}\n\n';
    message += '👆 Cliquez sur le lien pour accepter:\n';
    message += _inviteUrl!;

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inviter un proche')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _CardSection(
            title: 'Relation & confidentialité',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShareLevelSelector(
                  value: _level,
                  onChanged: (v) => setState(() => _level = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _theySeeMe,
                  onChanged: (v) => setState(() => _theySeeMe = v),
                  title: const Text('Autoriser ce proche à voir ma position'),
                  subtitle: const Text(
                    'Vous pourrez changer cela à tout moment',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _CardSection(
            title: 'Affecter aux zones (facultatif)',
            child: Column(
              children: [
                // Liste des zones (sans restrictions premium)
                _isLoadingZones
                    ? const Center(child: CircularProgressIndicator())
                    : _availableZones.isEmpty
                    ? const Text('Aucune zone de sécurité disponible')
                    : Column(
                        children: _availableZones.map((zone) {
                          final isSelected = _selectedZones[zone.id] ?? false;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setState(
                                () => _selectedZones[zone.id] = v ?? false,
                              );
                            },
                            title: Text(zone.name),
                            subtitle: Text(
                              'Rayon: ${zone.radiusMeters}m${zone.memberIds.isNotEmpty ? ' • ${zone.memberIds.length} proche(s)' : ''}',
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _CardSection(
            title: 'Sécurité du lien',
            child: Column(
              children: [
                _ExpirySelector(
                  value: _expiry,
                  onChanged: (d) => setState(() => _expiry = d),
                ),
                const SizedBox(height: 6),
                _UsesSelector(
                  value: _maxUses,
                  onChanged: (n) => setState(() => _maxUses = n),
                ),
                const SizedBox(height: 6),
                TextField(
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code PIN (optionnel)',
                    hintText: '4 chiffres',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _pin = v.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isGeneratingInvitation ? null : _generate,
              icon: _isGeneratingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(
                _isGeneratingInvitation ? 'Génération...' : 'Générer le lien',
              ),
            ),
          ),
          if (_generatedInvitation != null && _inviteUrl != null) ...[
            const SizedBox(height: 12),
            _GeneratedLinkCard(
              url: _inviteUrl!,
              expiresAt: _generatedInvitation!.expiresAt,
              uses: _generatedInvitation!.maxUses,
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: _inviteUrl!));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien copié dans le presse-papiers'),
                    ),
                  );
                }
              },
              onShare: () async {
                try {
                  final shareText = _buildShareMessage();
                  await Share.share(
                    shareText,
                    subject: 'Invitation AlertContact',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors du partage: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// ————————————————— Widgets réutilisables —————————————————

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardSection({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ShareLevelSelector extends StatelessWidget {
  final ShareLevel value;
  final ValueChanged<ShareLevel> onChanged;
  const _ShareLevelSelector({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile(
          value: ShareLevel.realtime,
          groupValue: value,
          onChanged: (v) => onChanged(v as ShareLevel),
          title: const Text('Temps réel'),
          subtitle: const Text('Partage continu de la position'),
        ),
        RadioListTile(
          value: ShareLevel.alertOnly,
          groupValue: value,
          onChanged: (v) => onChanged(v as ShareLevel),
          title: const Text('Uniquement alertes'),
          subtitle: const Text(
            'Position transmise seulement lors d\'une alerte',
          ),
        ),
        RadioListTile(
          value: ShareLevel.none,
          groupValue: value,
          onChanged: (v) => onChanged(v as ShareLevel),
          title: const Text('Aucun'),
          subtitle: const Text('Relation sans partage de position'),
        ),
      ],
    );
  }
}

class _ExpirySelector extends StatelessWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;
  const _ExpirySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String label(Duration d) {
      if (d.inMinutes == 15) return '15 min';
      if (d.inHours == 1) return '1 h';
      if (d.inHours == 24) return '24 h';
      return '7 j';
    }

    return Row(
      children: [
        const Icon(Icons.schedule),
        const SizedBox(width: 8),
        const Text('Expiration :'),
        const SizedBox(width: 8),
        DropdownButton<Duration>(
          value: value,
          items: const [
            DropdownMenuItem(
              value: Duration(minutes: 15),
              child: Text('15 min'),
            ),
            DropdownMenuItem(value: Duration(hours: 1), child: Text('1 h')),
            DropdownMenuItem(value: Duration(hours: 24), child: Text('24 h')),
            DropdownMenuItem(value: Duration(days: 7), child: Text('7 j')),
          ],
          onChanged: (d) => onChanged(d ?? value),
        ),
        const Spacer(),
        Text(label(value), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UsesSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _UsesSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [1, 3, 9999]; // 9999 = illimité (affiché "∞")
    String label(int v) => v == 9999 ? '∞ (illimité)' : v.toString();
    return Row(
      children: [
        const Icon(Icons.timelapse),
        const SizedBox(width: 8),
        const Text('Utilisations :'),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: value,
          items: options
              .map((n) => DropdownMenuItem(value: n, child: Text(label(n))))
              .toList(),
          onChanged: (n) => onChanged(n ?? value),
        ),
      ],
    );
  }
}

class _GeneratedLinkCard extends StatelessWidget {
  final String url;
  final DateTime expiresAt;
  final int uses;
  final VoidCallback onCopy, onShare;
  const _GeneratedLinkCard({
    required this.url,
    required this.expiresAt,
    required this.uses,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final left = expiresAt.difference(DateTime.now());
    final exp = left.isNegative ? 'expiré' : 'Expire dans ${_fmt(left)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link),
              const SizedBox(width: 8),
              const Text('Lien d\'invitation généré'),
              const Spacer(),
              Text(exp, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              url,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${d.inDays} j';
  }
}
