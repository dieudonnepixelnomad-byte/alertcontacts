import 'dart:developer';
import 'dart:io';

import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/services/deep_link_service.dart';
import 'package:alertcontacts/core/services/pending_deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasNavigated = false;
  bool _showEmailForm = false;

  final prefsService = PrefsService();

  @override
  void initState() {
    super.initState();
    log('LoginPage initState');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    // Réinitialiser le flag de navigation pour permettre une nouvelle tentative
    _hasNavigated = false;

    // Nettoyer les messages précédents
    context.read<AuthNotifier>().clearMessage();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Utiliser l'authentification Firebase par défaut
    context.read<AuthNotifier>().signInWithEmail(email, password);
  }

  void _handleGoogleSignIn() {
    // Réinitialiser le flag de navigation pour permettre une nouvelle tentative
    _hasNavigated = false;

    context.read<AuthNotifier>().clearMessage();
    context.read<AuthNotifier>().signInWithGoogle();
  }

  void _handleAppleSignIn() {
    _hasNavigated = false;

    context.read<AuthNotifier>().clearMessage();
    context.read<AuthNotifier>().signInWithApple();
  }

  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre adresse email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<AuthNotifier>().sendPasswordReset(
      _emailController.text.trim(),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est requise';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse email valide';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    return null;
  }

  void _handleAuthStateChange(AuthState authState) {
    if (_hasNavigated) return; // Éviter la navigation multiple

    if (authState.status == AuthStatus.authenticated) {
      log('LoginPage User Connected!');
      _hasNavigated = true;

      // Vérifier s'il y a un deep link en attente à rejouer
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Vérifier d'abord s'il y a un deep link en attente
          final hadPendingDeepLink =
              await PendingDeepLinkService.hasPendingDeepLink();

          // Tenter de rejouer un deep link en attente
          final router = GoRouter.of(context);
          await DeepLinkService.replayPendingDeepLink(router);

          // Attendre un peu pour voir si une navigation a eu lieu
          await Future.delayed(const Duration(milliseconds: 500));

          // Si on est toujours sur la page de login ET qu'il n'y avait pas de deep link en attente,
          // alors rediriger vers SplashPage
          if (mounted &&
              ModalRoute.of(context)?.settings.name == 'auth' &&
              !hadPendingDeepLink) {
            context.go(AppRoutes.splash);
          }
        }
      });
    } else if (authState.status == AuthStatus.needsEmailVerification) {
      log('LoginPage User — email verification pending, continuing to app');
      _hasNavigated = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.splash);
      });
    } else if (authState.message != null &&
        authState.status != AuthStatus.authenticating) {
      final isError = authState.status == AuthStatus.error;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.message!),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, child) {
        final authState = authNotifier.state;
        final isLoading = authState.status == AuthStatus.authenticating;

        // Gérer la navigation selon l'état d'authentification
        _handleAuthStateChange(authState);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F7),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lien "J'ai déjà un compte" en haut
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                PendingDeepLinkService.clearPendingDeepLink();
                                if (mounted) context.go(AppRoutes.register);
                              },
                        child: const Text(
                          'Créer un compte',
                          style: TextStyle(color: Color(0xFF006970)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Logo et titre
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 20),

                    Text(
                      'Connexion',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006970),
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Connectez-vous pour protéger vos proches',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // ── Bouton Google (priorité absolue) ──────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006970),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/google.png',
                                height: 20, width: 20),
                            const SizedBox(width: 10),
                            const Text('Continuer avec Google'),
                          ],
                        ),
                      ),
                    ),

                    // ── Bouton Apple (iOS uniquement) ──────────────────────
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _handleAppleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Color(0xFFD0D0D0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 22),
                              SizedBox(width: 8),
                              Text('Continuer avec Apple'),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Séparateur ─────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ou',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Email en option secondaire (TextButton) ────────────
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _showEmailForm = !_showEmailForm),
                        child: Text(
                          _showEmailForm
                              ? 'Masquer le formulaire'
                              : 'Continuer avec un e-mail',
                          style: const TextStyle(
                            color: Color(0xFF006970),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // ── Formulaire email (expandable) ─────────────────────
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _showEmailForm
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Adresse email',
                              hintText: 'votre@email.com',
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Colors.grey),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle:
                                  TextStyle(color: Colors.grey[400]!),
                              hintStyle: TextStyle(color: Colors.grey[400]!),
                            ),
                            validator:
                                _showEmailForm ? _validateEmail : null,
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: 'Votre mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle:
                                  TextStyle(color: Colors.grey[400]!),
                              hintStyle: TextStyle(color: Colors.grey[400]!),
                            ),
                            validator:
                                _showEmailForm ? _validatePassword : null,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: isLoading
                                    ? null
                                    : (v) => setState(
                                        () => _rememberMe = v ?? false),
                                activeColor: const Color(0xFF006970),
                              ),
                              const Text('Se souvenir de moi',
                                  style: TextStyle(color: Color(0xFF006970))),
                              const Spacer(),
                              TextButton(
                                onPressed:
                                    isLoading ? null : _handleForgotPassword,
                                child: const Text(
                                  'Mot de passe oublié',
                                  style: TextStyle(color: Color(0xFF006970)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF006970),
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                  : const Text('Se connecter'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

