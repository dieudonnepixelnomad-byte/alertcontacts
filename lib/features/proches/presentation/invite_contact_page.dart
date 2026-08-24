import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../features/paywall/presentation/paywall_page.dart';
import '../../../core/services/paywall_trigger_service.dart';
import '../providers/relationship_provider.dart';
import '../../../theme/colors.dart';

class InviteContactPage extends StatefulWidget {
  const InviteContactPage({super.key});

  @override
  State<InviteContactPage> createState() => _InviteContactPageState();
}

class _InviteContactPageState extends State<InviteContactPage> {
  final _prefs = PrefsService();
  final _nameController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  bool _checkingEligibility = true;
  String? _error;

  late final ApiInvitationService _invitationService;

  @override
  void initState() {
    super.initState();
    _invitationService =
        Provider.of<ApiInvitationService>(context, listen: false);
    _initAuth();
    _checkEligibility();
  }

  Future<void> _initAuth() async {
    final token = await _prefs.getBearerToken();
    if (token != null) _invitationService.setAuthToken(token);
  }

  /// Protège aussi l'accès direct à la route /proches/add. Ainsi, tous les
  /// boutons et les liens internes passent par la même règle avant d'afficher
  /// le formulaire d'invitation.
  Future<void> _checkEligibility() async {
    try {
      final profile = await _prefs.getUserProfile();

      if (profile?.hasPremiumAccess != true) {
        final relationships = context.read<RelationshipProvider>();
        await relationships.initialize();
        await relationships.loadRelationships();

        if (PaywallTriggerService.checkContactLimit(
          relationships.acceptedRelationships.length,
        )) {
          if (!mounted) return;
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const PaywallPage(trigger: 'contact_limit'),
            ),
          );
          return;
        }
      }
    } catch (_) {
      // Une indisponibilité réseau ne doit pas bloquer l'écran. L'API refuse
      // tout de même l'invitation si la limite est effectivement atteinte.
    }

    if (mounted) setState(() => _checkingEligibility = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _buildMessage(String name) {
    final greeting = name.isNotEmpty ? 'Salut $name,' : 'Salut,';
    return '$greeting j\'utilise AlertContacts pour garder mes proches en sécurité sans se déranger. '
        'Rejoins-moi pour qu\'on puisse s\'alerter si besoin.';
  }

  Future<void> _sendInvitation() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
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
      final message = '${_buildMessage(name)}\n\n$url';

      await Share.share(message, subject: 'Rejoins-moi sur AlertContacts');

      AnalyticsService().logOnboardingInvitationSent();
      if (mounted) setState(() => _sent = true);

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      log('InviteContactPage error: $e');
      if (mounted) {
        if (e is SubscriptionLimitException) {
          setState(() => _isSending = false);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaywallPage(trigger: 'contact_limit'),
            ),
          );
          return;
        }
        setState(() {
          _isSending = false;
          _error = 'Impossible d\'envoyer l\'invitation. Réessaie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingEligibility) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
          color: scheme.onSurface,
        ),
        title: Text(
          'Inviter un proche',
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  color: scheme.onSurface,
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

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: text.bodyMedium?.copyWith(color: scheme.onSurface),
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
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isSending ? null : _sendInvitation,
                style: FilledButton.styleFrom(
                  backgroundColor: _sent ? AppColors.safe : AppColors.teal,
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
