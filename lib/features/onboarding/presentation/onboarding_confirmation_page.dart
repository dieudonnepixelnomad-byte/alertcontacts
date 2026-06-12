import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class OnboardingConfirmationPage extends StatelessWidget {
  const OnboardingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Icône succès
              Container(
                width: 110,
                height: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.safe,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Tout est prêt.',
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 24),

              _CheckItem(label: 'Ton compte AlertContacts est créé'),
              const SizedBox(height: 10),
              _CheckItem(label: 'Ta première zone de sécurité est active'),
              const SizedBox(height: 10),
              _CheckItem(
                  label:
                      'Invitation envoyée — alertes actives dès l\'acceptation'),

              const Spacer(flex: 3),

              FilledButton(
                onPressed: () async {
                  final prefs = PrefsService();
                  await prefs.setOnboardingDone();
                  await prefs.setOnboardingPhase(3);
                  if (context.mounted) {
                    context.go(AppRoutes.appShell);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accéder à AlertContacts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  const _CheckItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.safe, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: text.bodyLarge?.copyWith(height: 1.3),
          ),
        ),
      ],
    );
  }
}
