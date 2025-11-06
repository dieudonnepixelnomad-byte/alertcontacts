import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/l10n_helper.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../../core/services/pending_deep_link_service.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _listenerInitialized = false;

  void _initializeListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;
    
    final authNotifier = context.read<AuthNotifier>();
    authNotifier.addListener(() {
      if (!mounted) return;
      
      final authState = authNotifier.state;
      if (authState.status == AuthStatus.unauthenticated && authState.message != null && authState.message!.contains('reset')) {
        setState(() {
          _emailSent = true;
        });
      } else if (authState.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.message ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context
          .read<AuthNotifier>()
          .sendPasswordReset(_emailController.text.trim());
    }
  }

  void _onBackToLogin() async {
    // Nettoyer les deep links en attente si l'utilisateur annule l'auth
    await PendingDeepLinkService.clearPendingDeepLink();
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackToLogin,
        ),
      ),
      body: Consumer<AuthNotifier>(
        builder: (context, authNotifier, child) {
          _initializeListener();
          final authState = authNotifier.state;
          final isLoading = authState.status == AuthStatus.authenticating;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Icône
                  Icon(Icons.lock_reset, size: 80, color: AppColors.teal),

                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    _emailSent
                        ? context.l10n.emailVerificationTitle
                        : context.l10n.forgotPasswordTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _emailSent
                        ? context.l10n.forgotPasswordEmailSent
                        : context.l10n.forgotPasswordDescription,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  if (!_emailSent) ...[
                    // Formulaire
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Champ email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: context.l10n.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.teal),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.emailRequired;
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return context.l10n.emailInvalid;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Bouton d'envoi
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onSendResetEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      context.l10n.sendResetLink,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Email envoyé - Actions
                    Column(
                      children: [
                        // Bouton pour renvoyer l'email
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _onSendResetEmail,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.teal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Renvoyer l\'email',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bouton retour à la connexion
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onBackToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              context.l10n.backToLogin,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Lien retour à la connexion (si email pas encore envoyé)
                  if (!_emailSent)
                    TextButton(
                      onPressed: _onBackToLogin,
                      child: Text(
                        'Retour à la connexion',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
