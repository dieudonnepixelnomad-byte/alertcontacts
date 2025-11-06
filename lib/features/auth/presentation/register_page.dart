import 'dart:io' show Platform;
import 'package:alertcontacts/core/utils/l10n_helper.dart';
import 'package:alertcontacts/router/app_router.dart';
import 'package:alertcontacts/core/services/deep_link_service.dart';
import 'package:alertcontacts/core/services/pending_deep_link_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscurePwd = true;
  bool _obscureCfm = true;
  bool _acceptTerms = false;

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // Nettoyer les messages d'erreur précédents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthNotifier>().clearMessage();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseAcceptTerms),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Nettoyer les messages précédents
    context.read<AuthNotifier>().clearMessage();

    await context.read<AuthNotifier>().registerWithEmail(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );
  }

  Future<void> _onGoogle() async {
    context.read<AuthNotifier>().clearMessage();
    await context.read<AuthNotifier>().signInWithGoogle();
  }

  Future<void> _onApple() async {
    context.read<AuthNotifier>().clearMessage();
    await context.read<AuthNotifier>().signInWithApple();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.nameRequired;
    }
    if (value.trim().length < 2) {
      return context.l10n.nameTooShort;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.emailRequired;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return context.l10n.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.passwordRequired;
    }
    if (value.length < 6) {
      return context.l10n.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.confirmPasswordRequired;
    }
    if (value != _password.text) {
      return context.l10n.passwordsDoNotMatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const teal = Color(0xFF006970);
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, child) {
        final authState = authNotifier.state;
        final isLoading = authState.status == AuthStatus.authenticating;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          if (authState.status == AuthStatus.authenticated) {
            // Vérifier d'abord s'il y a un deep link en attente
            final hadPendingDeepLink = await PendingDeepLinkService.hasPendingDeepLink();
            
            // Vérifier s'il y a un deep link en attente à rejouer
            final router = GoRouter.of(context);
            await DeepLinkService.replayPendingDeepLink(router);
            
            // Attendre un peu pour voir si une navigation a eu lieu
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Si on est toujours sur la page d'inscription ET qu'il n'y avait pas de deep link en attente,
            // alors rediriger vers appShell
            if (mounted && 
                ModalRoute.of(context)?.settings.name == '/register' && 
                !hadPendingDeepLink) {
              context.go(AppRoutes.appShell);
            }
          } else if (authState.status == AuthStatus.needsEmailVerification) {
            context.go(AppRoutes.emailVerification);
          } else if (authState.message != null) {
            final isError = authState.status == AuthStatus.error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authState.message!),
                backgroundColor: isError ? Colors.red : Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F7),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Logo
                      Image.asset('assets/images/logo.png', height: 50),
                      const SizedBox(height: 16),

                      Text(
                        context.l10n.createYourAccount,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: teal,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        context.l10n.registerSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: context.l10n.fullName,
                                hintText: 'Jean Dupont',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                              ),
                              validator: _validateName,
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: context.l10n.email,
                                hintText: 'jean@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: const OutlineInputBorder(),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePwd,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: context.l10n.password,
                                hintText: 'Votre mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                helperText: context.l10n.passwordHintShort,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePwd = !_obscurePwd,
                                  ),
                                  icon: Icon(
                                    _obscurePwd
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 14),

                            // Confirm password
                            TextFormField(
                              controller: _confirm,
                              obscureText: _obscureCfm,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: context.l10n.confirmPassword,
                                hintText: 'Confirmez votre mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureCfm = !_obscureCfm,
                                  ),
                                  icon: Icon(
                                    _obscureCfm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: _validateConfirmPassword,
                              onFieldSubmitted: (_) => _onRegister(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Terms & Privacy
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: isLoading
                                ? null
                                : (v) =>
                                      setState(() => _acceptTerms = v ?? false),
                            activeColor: teal,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: context.l10n.iAgreeWith,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurface.withOpacity(.8),
                                    ),
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () {
                                        // TODO: open Terms
                                      },
                                      child: Text(
                                        context.l10n.termsOfUse,
                                        style: const TextStyle(
                                          color: teal,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: ' ${context.l10n.and} '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () {
                                        // TODO: open Privacy
                                      },
                                      child: Text(
                                        context.l10n.privacyPolicy,
                                        style: const TextStyle(
                                          color: teal,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Register button
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: isLoading ? null : _onRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.l10n.createAccount),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Divider "Or"
                      Row(
                        children: [
                          Expanded(child: Divider(color: cs.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(.6),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: cs.outlineVariant)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Boutons de connexion sociale
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Google',
                              onPressed: isLoading ? null : _onGoogle,
                              style: _SocialStyle.google,
                              iconAsset: 'assets/icons/google.png',
                            ),
                          ),

                          if (_isIOS) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isLoading ? null : _onApple,
                                icon: const Icon(Icons.apple, size: 24),
                                label: const Text('Apple'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Footer: déjà un compte ?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.l10n.alreadyHaveAccount,
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    // Nettoyer les deep links en attente si l'utilisateur change de page
                                    await PendingDeepLinkService.clearPendingDeepLink();
                                    context.go(AppRoutes.auth);
                                  },
                            child: Text(
                              context.l10n.login,
                              style: const TextStyle(
                                color: teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _SocialStyle { apple, google }

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? iconAsset;
  final _SocialStyle style;
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.style,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final isApple = style == _SocialStyle.apple;
    final bg = isApple ? Colors.black : Colors.white;
    final fg = isApple ? Colors.white : Colors.black87;
    final side = isApple
        ? BorderSide.none
        : const BorderSide(color: Color(0xFFE0E0E0));

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: side,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(iconAsset!, height: 18, width: 18),
              ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
