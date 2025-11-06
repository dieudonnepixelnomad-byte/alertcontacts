// lib/features/invitations/presentation/accept_invitation_page.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';

// Route attendue: /invitations/accept?t=<token>&pin=<optionnel>
class AcceptInvitationPage extends StatefulWidget {
  final String token;
  final String? prefilledPin;
  const AcceptInvitationPage({
    super.key,
    required this.token,
    this.prefilledPin,
  });

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage>
    with TickerProviderStateMixin {
  late final ApiInvitationService _service;
  late final PrefsService _prefsService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Invitation? _invitation;
  String? _error;
  bool _loading = true;
  bool _pinRequired =
      false; // Force l'affichage du PIN si détecté comme nécessaire

  // choix utilisateur
  ShareLevel _level = ShareLevel.alertOnly;
  final _zonesAccepted = <String, bool>{};
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = ApiInvitationService();
    _prefsService = PrefsService();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    if (widget.prefilledPin != null) _pinCtrl.text = widget.prefilledPin!;
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Configurer le token d'authentification
      final token = await _prefsService.getBearerToken();
      if (token != null) {
        _service.setAuthToken(token);
      }

      // Pré-remplir le PIN si fourni dans l'URL
       if (widget.prefilledPin != null) {
         _pinCtrl.text = widget.prefilledPin!;
       }

       final invitation = await _service.checkInvitation(widget.token);
       
       // Utiliser le PIN de l'invitation si disponible (priorité sur le prefilledPin)
       if (invitation.pin != null && invitation.pin!.isNotEmpty) {
         _pinCtrl.text = invitation.pin!;
         _pinRequired = true;
       } else {
         // Détecter si un PIN est probablement requis (logique similaire au service fake)
         // Cette logique peut être ajustée selon les besoins réels de l'API
         final tokenRequiresPin = widget.token.length % 2 == 0;
         if (tokenRequiresPin || widget.prefilledPin != null) {
           _pinRequired = true;
         }
       }

      setState(() {
        _loading = false;
        _invitation = invitation;
        _level = invitation.defaultShareLevel;
        for (final zone in invitation.suggestedZones) {
          _zonesAccepted[zone] = true; // coché par défaut
        }
      });

      // Démarrer l'animation une fois les données chargées
      _animationController.forward();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _getErrorMessage(e);
      });
    }
  }

  Future<void> _onAccept() async {
    log('AcceptationPage: Invitation: $_invitation');
    if (_invitation == null) return;
    setState(() => _loading = true);

    final acceptedZones = _zonesAccepted.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    log('AcceptationPage: Accepted Zones: $acceptedZones');

    try {
      // S'assurer que le token est configuré
      final authToken = await _prefsService.getBearerToken();
      if (authToken != null) {
        _service.setAuthToken(authToken);
      }

      log('AcceptInvitationPage - CodePin: ${_pinCtrl.text}');

      await _service.acceptInvitation(
        token: widget.token,
        pin: _pinCtrl.text.isEmpty ? null : _pinCtrl.text,
        shareLevel: _level,
        acceptedZones: acceptedZones,
      );

      log('AcceptationPage: Acceptation réussie');

      setState(() => _loading = false);
      if (!mounted) return;

      // Succès : afficher un dialog de confirmation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Invitation acceptée !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous êtes maintenant connecté(e) avec ${_invitation!.inviterName}.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Niveau de partage : ${_level.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              if (acceptedZones.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${acceptedZones.length} zone(s) acceptée(s)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  context.go(AppRoutes.appShell);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuer'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        // Si c'est une erreur de PIN, on force l'affichage du champ PIN
        if (e is InvalidPinException) {
          _pinRequired = true;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(_getErrorMessage(e))),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Extrait le message d'erreur approprié selon le type d'exception
  String _getErrorMessage(dynamic error) {
    if (error is InvalidPinException) {
      return '🔒 ${error.message}\nVérifiez le code PIN et réessayez.';
    } else if (error is InvitationNotFoundException) {
      return '❌ ${error.message}\nCe lien d\'invitation n\'est pas valide.';
    } else if (error is InvitationExpiredException) {
      return '⏰ ${error.message}\nDemandez un nouveau lien d\'invitation.';
    } else if (error is InvitationRefusedException) {
      return '🚫 ${error.message}';
    } else if (error is ValidationException) {
      return '⚠️ ${error.message}\nVérifiez vos informations.';
    } else if (error is RelationAlreadyExistsException) {
      return '👥 ${error.message}\nVous êtes déjà connecté(e) à cette personne.';
    } else {
      // Pour les autres exceptions, on utilise toString() et on nettoie
      final message = error.toString().replaceFirst('Exception: ', '');
      return '❌ Une erreur s\'est produite\n$message';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rejoindre un proche',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withOpacity(0.05), cs.surface, cs.surface],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 16),
                    Text(
                      'Chargement de l\'invitation...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : (_error != null)
            ? _ErrorState(message: _error!, onRetry: _load)
            : _invitation == null
            ? const SizedBox.shrink()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 120, 20, 32),
                    children: [
                      // Header avec importance visuelle
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withOpacity(0.1),
                              cs.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 48,
                              color: cs.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Invitation importante',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quelqu\'un souhaite vous ajouter à son réseau de sécurité',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _InviterCard(
                        name: _invitation!.inviterName,
                        avatarUrl: '', // TODO: ajouter avatar
                      ),
                      const SizedBox(height: 20),

                      _CardSection(
                        title: 'Choisir ce que vous partagez',
                        icon: Icons.share_location_rounded,
                        iconColor: Colors.orange,
                        child: Column(
                          children: [
                            _ShareLevelTile(
                              level: ShareLevel.realtime,
                              groupValue: _level,
                              onChanged: (v) => setState(() => _level = v!),
                              title: 'Temps réel',
                              subtitle:
                                  'Position en continu (consomme plus de batterie)',
                              icon: Icons.my_location_rounded,
                              color: Colors.red,
                            ),
                            _ShareLevelTile(
                              level: ShareLevel.alertOnly,
                              groupValue: _level,
                              onChanged: (v) => setState(() => _level = v!),
                              title: 'Alertes uniquement',
                              subtitle:
                                  'Position partagée seulement en cas d\'alerte',
                              icon: Icons.notification_important_rounded,
                              color: Colors.orange,
                            ),
                            _ShareLevelTile(
                              level: ShareLevel.none,
                              groupValue: _level,
                              onChanged: (v) => setState(() => _level = v!),
                              title: 'Aucun partage',
                              subtitle: 'Relation sans partage de position',
                              icon: Icons.visibility_off_rounded,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      // Zones suggérées
                      if (_invitation!.suggestedZones.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _CardSection(
                          title: 'Zones suggérées',
                          icon: Icons.place_rounded,
                          iconColor: Colors.green,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_invitation!.inviterName} vous suggère d\'être affecté(e) à ces zones :',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._invitation!.suggestedZones.map(
                                (zone) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CheckboxListTile(
                                    value: _zonesAccepted[zone] ?? false,
                                    onChanged: (v) => setState(
                                      () => _zonesAccepted[zone] = v ?? false,
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.shield_rounded,
                                          size: 18,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            zone,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    dense: true,
                                    activeColor: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // PIN si requis, si un PIN a été fourni dans l'URL, ou si détecté comme nécessaire
                      if (_invitation!.requiresPin ||
                          widget.prefilledPin != null ||
                          _pinRequired) ...[
                        const SizedBox(height: 16),
                        _CardSection(
                          title: 'Code PIN requis',
                          icon: Icons.lock_rounded,
                          iconColor: Colors.purple,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.security_rounded,
                                      color: Colors.purple.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pinRequired
                                            ? 'Un code PIN est requis pour accepter cette invitation.'
                                            : 'Cette invitation nécessite un code PIN.',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _pinCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Code PIN (4 chiffres)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.pin_rounded),
                                  filled: true,
                                  fillColor: cs.surfaceVariant.withOpacity(0.3),
                                  hintText: 'Entrez le code PIN',
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                ),
                                onChanged: (value) {
                                  // Limiter à 4 chiffres
                                  if (value.length > 4) {
                                    _pinCtrl.text = value.substring(0, 4);
                                    _pinCtrl.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: _pinCtrl.text.length,
                                          ),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Message de l'inviteur
                      if (_invitation!.message != null &&
                          _invitation!.message!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _CardSection(
                          title: 'Message personnel',
                          icon: Icons.message_rounded,
                          iconColor: Colors.pink,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.withOpacity(0.1),
                                  Colors.pink.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.pink.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote,
                                      color: Colors.pink.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Message de ${_invitation!.inviterName}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.pink.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _invitation!.message!,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                    color: cs.onSurface.withOpacity(.85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Boutons d'action avec design amélioré
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: _onAccept,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text(
                                  'Accepter l\'invitation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go(AppRoutes.appShell),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text(
                                  'Refuser',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                  side: BorderSide(color: Colors.red.shade600),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _label(ShareLevel level) {
    switch (level) {
      case ShareLevel.realtime:
        return 'Temps réel';
      case ShareLevel.alertOnly:
        return 'Alertes uniquement';
      case ShareLevel.none:
        return 'Aucun partage';
    }
  }
}

/// ——— UI helpers ———

class _ShareLevelTile extends StatelessWidget {
  final ShareLevel level;
  final ShareLevel groupValue;
  final ValueChanged<ShareLevel?> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ShareLevelTile({
    required this.level,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = level == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.1)
            : cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<ShareLevel>(
        value: level,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Text(
            subtitle,
            style: TextStyle(
              color: isSelected
                  ? color.withOpacity(0.8)
                  : cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        activeColor: color,
      ),
    );
  }
}

class _InviterCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  const _InviterCard({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.15), cs.primary.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary,
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'vous invite à devenir proches',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(.75),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final Color iconColor;

  const _CardSection({
    required this.title,
    required this.child,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Oups ! Une erreur s\'est produite',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
