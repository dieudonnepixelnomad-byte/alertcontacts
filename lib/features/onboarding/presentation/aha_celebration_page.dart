import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class AhaCelebrationPage extends StatefulWidget {
  const AhaCelebrationPage({super.key});

  @override
  State<AhaCelebrationPage> createState() => _AhaCelebrationPageState();
}

class _AhaCelebrationPageState extends State<AhaCelebrationPage> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logOnboardingCelebrationViewed();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Confetti aligné en haut-centre
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.teal,
                AppColors.safe,
                AppColors.alert,
                Color(0xFFFFD700),
                Color(0xFF9C27B0),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Icône centrale
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 64,
                      color: AppColors.teal,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'C\'est ça, AlertContacts.',
                    textAlign: TextAlign.center,
                    style: text.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Tu viens de vivre exactement ce que ressent un proche protégé. En temps réel. Même quand l\'app est fermée.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: scheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // CTA principal
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go(AppRoutes.auth),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Créer mon compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CTA secondaire
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Rejouer l\'alerte',
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
