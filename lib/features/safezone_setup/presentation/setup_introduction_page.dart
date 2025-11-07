import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../../core/services/prefs_service.dart';

class SetupIntroductionPage extends StatefulWidget {
  const SetupIntroductionPage({super.key});

  @override
  State<SetupIntroductionPage> createState() => _SetupIntroductionPageState();
}

class _SetupIntroductionPageState extends State<SetupIntroductionPage> {
  final PrefsService _prefsService = PrefsService();

  /// Marque le setup comme terminé et navigue vers l'app shell
  Future<void> _skipSetup() async {
    await _prefsService.setInitialSetupDone();
    if (mounted) {
      context.go(AppRoutes.appShell);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: _skipSetup,
        ),
        actions: [
          TextButton(
            onPressed: _skipSetup,
            child: Text(
              'Ignorer',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Indicateur de progression
              _buildProgressIndicator(context, currentStep: 1, totalSteps: 4),

              const SizedBox(height: 40),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration principale
                    _buildMainIllustration(context),

                    const SizedBox(height: 30),

                    // Titre principal
                    Text(
                      'Protégeons nos proches',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Commençons par créer votre première zone sécurisée.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Points clés
                    _buildFeaturesList(context),
                  ],
                ),
              ),

              // Bouton principal
              _buildPrimaryButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required int currentStep,
    required int totalSteps,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive || isCurrent
                  ? AppColors.teal
                  : cs.onSurface.withOpacity(0.1),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMainIllustration(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de sécurité
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.safe, width: 2),
            ),
          ),
          // Icône famille
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 40,
              color: AppColors.teal,
            ),
          ),
          // Badge de protection
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.safe,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.safe.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final features = [
      {
        'icon': Icons.location_on_outlined,
        'title': 'Définir une zone',
        'description':
            'Créez un périmètre de sécurité autour des lieux importants',
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Recevoir des alertes',
        'description': 'Soyez notifié quand vos proches entrent ou sortent',
      },
      {
        'icon': Icons.people_outline,
        'title': 'Inviter vos proches',
        'description':
            'Partagez votre localisation avec les personnes de confiance',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.safezoneSetup + '/zone-config');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Commencer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
