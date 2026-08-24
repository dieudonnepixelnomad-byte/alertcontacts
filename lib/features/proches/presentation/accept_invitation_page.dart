import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../features/paywall/presentation/paywall_page.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/app_review_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../auth/providers/auth_notifier.dart';
import 'invitation_success_page.dart';

// Route: /invitations/accept?t=<token>&pin=<optionnel>
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
    with SingleTickerProviderStateMixin {
  late final ApiInvitationService _service;
  late final PrefsService _prefsService;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  Invitation? _invitation;
  String? _error;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _service = ApiInvitationService();
    _prefsService = PrefsService();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final token = await _prefsService.getBearerToken();
      if (token != null) _service.setAuthToken(token);
      final invitation = await _service.checkInvitation(widget.token);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _invitation = invitation;
      });
      _animCtrl.forward();
    } catch (e) {
      await AppReviewService().recordRecentError();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _parseError(e);
      });
    }
  }

  Future<void> _accept() async {
    if (_invitation == null || _accepting) return;
    setState(() => _accepting = true);
    try {
      final authToken = await _prefsService.getBearerToken();
      if (authToken != null) _service.setAuthToken(authToken);
      await _service.acceptInvitation(
        token: widget.token,
        pin: widget.prefilledPin,
        shareLevel: ShareLevel.realtime,
        acceptedZones: [],
      );
      if (!mounted) return;
      final user = context.read<AuthNotifier>().user;
      final initials = user != null && user.name.isNotEmpty
          ? user.name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
          : '?';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InvitationSuccessPage(
            inviterName: _invitation!.inviterName,
            myInitials: initials,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      if (e is SubscriptionLimitException) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaywallPage(trigger: 'contact_limit'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_parseError(e)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _refuse() => context.go(AppRoutes.appShell);

  String _parseError(dynamic e) {
    if (e is InvalidPinException) return 'Code PIN incorrect. Réessayez.';
    if (e is InvitationNotFoundException) return 'Lien invalide ou expiré.';
    if (e is InvitationExpiredException) return 'Ce lien a expiré. Demandez un nouveau.';
    if (e is RelationAlreadyExistsException) return 'Vous êtes déjà connecté(e) à cette personne.';
    if (e is SubscriptionLimitException) return e.message;
    return 'Une erreur s\'est produite. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : _invitation == null
                    ? const SizedBox.shrink()
                    : FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: _InvitationContent(
                            invitation: _invitation!,
                            accepting: _accepting,
                            onAccept: _accept,
                            onRefuse: _refuse,
                          ),
                        ),
                      ),
      ),
    );
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────

class _InvitationContent extends StatelessWidget {
  final Invitation invitation;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  const _InvitationContent({
    required this.invitation,
    required this.accepting,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final name = invitation.inviterName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasMessage = invitation.message != null && invitation.message!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 24),

        // Chip "AlertContacts · Invitation"
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.pink],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AlertContacts · Invitation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Avatar centré
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.orange,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Titre
        Text(
          '$name t\'a invité·e sur AlertContacts',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          'Pour rester connectés en sécurité.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Message personnel
        if (hasMessage) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SON MESSAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '« ${invitation.message!} »',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.black.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Info mutuelles
        Text(
          'AlertContacts te permet de voir vos positions mutuelles en temps réel — toi et $name.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.45),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // CTA accepter
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: accepting ? null : onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: accepting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accepter l\'invitation →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Lien "Refuser"
        Center(
          child: TextButton(
            onPressed: onRefuse,
            child: Text(
              'Refuser',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded, size: 52, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.gray600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
