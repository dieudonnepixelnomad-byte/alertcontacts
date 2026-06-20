import 'dart:io';

import 'package:alertcontacts/theme/colors.dart';
import 'package:alertcontacts/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../router/app_router.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleAuthState(AuthState state) {
    if (_hasNavigated) return;

    if (state.status == AuthStatus.authenticated) {
      _hasNavigated = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoutes.appShell);
      });
    } else if (state.message == 'magic_link_sent') {
      _hasNavigated = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final email = Uri.encodeComponent(_emailController.text.trim());
        context.push('${AppRoutes.magicLinkSent}?email=$email');
        _hasNavigated = false;
        context.read<AuthNotifier>().clearMessage();
      });
    } else if (state.message != null &&
        state.status != AuthStatus.authenticating &&
        state.message != 'magic_link_sent') {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message!),
            backgroundColor: state.status == AuthStatus.error
                ? AppColors.danger
                : AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  void _sendMagicLink() {
    if (!_formKey.currentState!.validate()) return;
    _hasNavigated = false;
    context.read<AuthNotifier>().clearMessage();
    context.read<AuthNotifier>().sendMagicLink(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        _handleAuthState(auth.state);
        final isLoading = auth.state.status == AuthStatus.authenticating;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FA),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 56,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Bienvenue',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      color: AppColors.gray900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Aucun mot de passe à retenir',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Auth buttons (same for both tabs)
                  _AuthButtons(
                    isLoading: isLoading,
                    onGoogle: () {
                      _hasNavigated = false;
                      auth.clearMessage();
                      auth.signInWithGoogle();
                    },
                    onApple: Platform.isIOS
                        ? () {
                            _hasNavigated = false;
                            auth.clearMessage();
                            auth.signInWithApple();
                          }
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Email separator
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OU PAR EMAIL',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.gray400,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Email form
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _sendMagicLink(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Adresse email requise';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                            .hasMatch(v.trim())) {
                          return 'Adresse email invalide';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.gray400,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Magic Link CTA
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendMagicLink,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Recevoir mon lien de connexion'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CGU
                  Column(
                    children: [
                      Text(
                        'En continuant, tu acceptes nos',
                        textAlign: TextAlign.center,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                            ),
                            child: Text(
                              'CGU',
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'et notre',
                            style: AppTypography.textTheme.bodySmall
                                ?.copyWith(color: AppColors.gray400),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                            ),
                            child: Text(
                              'Politique de confidentialité',
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogle;
  final VoidCallback? onApple;

  const _AuthButtons({
    required this.isLoading,
    required this.onGoogle,
    this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Apple first (Apple requirement when Google is present)
        if (onApple != null) ...[
          _SocialButton(
            onPressed: isLoading ? null : onApple,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
            label: 'Continuer avec Apple',
          ),
          const SizedBox(height: 12),
        ],

        // Google
        _SocialButton(
          onPressed: isLoading ? null : onGoogle,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          border: BorderSide(color: AppColors.gray200),
          icon: Image.asset(
            'assets/icons/google.png',
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.g_mobiledata,
              size: 22,
            ),
          ),
          label: 'Continuer avec Google',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? border;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: border ?? const BorderSide(color: Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
