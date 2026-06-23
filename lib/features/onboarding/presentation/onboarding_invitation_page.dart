import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class OnboardingInvitationPage extends StatefulWidget {
  const OnboardingInvitationPage({super.key});

  @override
  State<OnboardingInvitationPage> createState() =>
      _OnboardingInvitationPageState();
}

class _OnboardingInvitationPageState extends State<OnboardingInvitationPage> {
  final _prefs = PrefsService();
  final _nameController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  String? _error;

  late final ApiInvitationService _invitationService;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logInvitationScreenViewed();
    _invitationService =
        Provider.of<ApiInvitationService>(context, listen: false);
    _initAuth();
  }

  Future<void> _initAuth() async {
    final token = await _prefs.getBearerToken();
    if (token != null) _invitationService.setAuthToken(token);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _buildMessage(String persona, String name) {
    final personaLabel = {
      'children': 'ma famille',
      'parents': 'ma famille',
      'partner': 'toi',
      'friends': 'toi',
      'family': 'ma famille',
    }[persona] ??
        'toi';

    final greeting = name.isNotEmpty ? 'Salut $name,' : 'Salut,';
    return '$greeting j\'utilise AlertContacts pour garder $personaLabel en sécurité sans se déranger. '
        'Rejoins-moi pour qu\'on puisse s\'alerter si besoin.';
  }

  Future<void> _sendInvitation() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final persona = await _prefs.getOnboardingPersona() ?? 'family';
      final name = _nameController.text.trim();

      final invitation = await _invitationService.createInvitation(
        defaultShareLevel: ShareLevel.alertOnly,
        suggestedZones: [],
        expiresInHours: 24,
        maxUses: 1,
        requirePin: false,
        message: null,
      );

      final url = ApiConfig.getInvitationUrl(invitation.token);
      final message = '${_buildMessage(persona, name)}\n\n$url';

      await Share.share(message, subject: 'Rejoins-moi sur AlertContacts');

      if (name.isNotEmpty) await _prefs.setOnboardingInviteeName(name);
      await _prefs.setOnboardingInviteDone();
      await _prefs.setOnboardingDone();

      AnalyticsService().logOnboardingInvitationSent();
      AnalyticsService().logOnboardingCompleted();
      if (mounted) setState(() => _sent = true);

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go(AppRoutes.appShell);
    } catch (e) {
      log('OnboardingInvitationPage error: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = 'Impossible d\'envoyer l\'invitation. Réessaie.';
        });
      }
    }
  }

  Future<void> _skip() async {
    AnalyticsService().logOnboardingInvitationSkipped();
    AnalyticsService().logOnboardingCompleted();
    await _prefs.setOnboardingInviteDone();
    await _prefs.setOnboardingDone();
    if (mounted) context.go(AppRoutes.appShell);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bouton passer
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSending ? null : _skip,
                  child: Text(
                    'Passer',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_outlined,
                    size: 44, color: AppColors.teal),
              ),

              const SizedBox(height: 24),

              Text(
                'Invite un proche à rejoindre AlertContacts',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Tu recevras une alerte dès qu\'il entre ou sort d\'une zone que tu auras créée.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Champ prénom
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Prénom (optionnel)',
                  hintText: 'Marie, Thomas...',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                ),
              ),

              const SizedBox(height: 12),

              // Niveau de partage info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.teal, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Niveau par défaut : Alertes uniquement — le moins intrusif.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isSending ? null : _sendInvitation,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _sent ? AppColors.safe : AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_sent ? Icons.check : Icons.send_outlined),
                label: Text(
                  _sent ? 'Invitation envoyée ✓' : 'Envoyer l\'invitation',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
