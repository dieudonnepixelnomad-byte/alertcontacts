import 'dart:developer';

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
  bool _hasNavigated = false; // Flag pour éviter la navigation multiple

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
          final hadPendingDeepLink = await PendingDeepLinkService.hasPendingDeepLink();
          
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
      log('LoginPage User Needs Email Verification!');
      _hasNavigated = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.emailVerification);
        }
      });
    } else if (authState.message != null && authState.status != AuthStatus.authenticating) {
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
          backgroundColor: const Color(0xFFF3F6F7), // AppTheme.backgroundColor
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo et titre
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 24),

                    Text(
                      'Connexion',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(
                              0xFF006970,
                            ), // AppTheme.primaryColor
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Connectez-vous pour protéger vos proches',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Champ email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Adresse email',
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 16),

                    // Champ mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: 'Votre mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 16),

                    // Options
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                          activeColor: const Color(
                            0xFF006970,
                          ), // AppTheme.primaryColor
                        ),
                        Text(
                          'Se souvenir de moi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: isLoading ? null : _handleForgotPassword,
                          child: const Text(
                            'Mot de passe oublié',
                            style: TextStyle(
                              color: Color(0xFF006970), // AppTheme.primaryColor
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bouton de connexion
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006970),
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
                            : const Text('Se connecter'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Boutons de connexion sociale
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            onPressed: isLoading ? null : _handleGoogleSignIn,
                            style: _SocialStyle.google,
                            iconAsset: 'assets/icons/google.png',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Lien vers l'inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  // Nettoyer les deep links en attente si l'utilisateur change de page
                                  await PendingDeepLinkService.clearPendingDeepLink();
                                  context.go(AppRoutes.register);
                                },
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: Color(0xFF006970), // AppTheme.primaryColor
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
