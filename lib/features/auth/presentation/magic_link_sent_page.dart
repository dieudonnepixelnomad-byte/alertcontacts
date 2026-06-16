import 'dart:async';

import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/theme/colors.dart';
import 'package:alertcontacts/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MagicLinkSentPage extends StatefulWidget {
  final String email;
  const MagicLinkSentPage({super.key, required this.email});

  @override
  State<MagicLinkSentPage> createState() => _MagicLinkSentPageState();
}

class _MagicLinkSentPageState extends State<MagicLinkSentPage> {
  static const _cooldown = 30;
  int _secondsLeft = _cooldown;
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    await context.read<AuthNotifier>().sendMagicLink(widget.email);
    if (mounted) {
      setState(() => _isResending = false);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien renvoyé !'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openMailApp() async {
    final uri = Uri.parse('mailto:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Consulte ta boîte mail',
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'On a envoyé un lien de connexion à',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.email,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Clique sur le lien dans l\'email pour te connecter. Il est valable 1 heure.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                ),
              ),

              const Spacer(flex: 2),

              // Open mail app CTA
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openMailApp,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ouvrir mon application mail'),
                ),
              ),

              const SizedBox(height: 16),

              // Resend button with countdown
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: (_secondsLeft == 0 && !_isResending)
                      ? _resend
                      : null,
                  child: _isResending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          _secondsLeft > 0
                              ? 'Renvoyer dans ${_secondsLeft}s'
                              : 'Renvoyer le lien',
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
