import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class OnboardingResumePage extends StatefulWidget {
  const OnboardingResumePage({super.key});

  @override
  State<OnboardingResumePage> createState() => _OnboardingResumePageState();
}

class _OnboardingResumePageState extends State<OnboardingResumePage> {
  final _prefs = PrefsService();

  Future<String> _nextRoute() async {
    final userSetupDone = await _prefs.isUserSetupDone();
    if (!userSetupDone) return AppRoutes.onboardingPersonalization;

    final inviteDone = await _prefs.isOnboardingInviteDone();
    if (!inviteDone) return AppRoutes.onboardingInvitation;

    final notifAsked = await _prefs.isOnboardingNotifPermAsked();
    if (!notifAsked) return AppRoutes.onboardingNotificationPermission;

    final zoneCreated = await _prefs.isOnboardingZoneCreated();
    if (!zoneCreated) return AppRoutes.onboardingZoneCreation;

    return AppRoutes.onboardingConfirmation;
  }

  Future<void> _resume() async {
    final route = await _nextRoute();
    if (mounted) context.go(route);
  }

  Future<void> _bypass() async {
    await _prefs.setOnboardingDone();
    if (mounted) context.go(AppRoutes.appShell);
  }

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

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 56,
                color: AppColors.teal,
              ),

              const SizedBox(height: 28),

              Text(
                'On reprend là où tu t\'es arrêté ?',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Quelques étapes restent à compléter pour que tu reçoives ta première alerte.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              FilledButton(
                onPressed: _resume,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reprendre',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: _bypass,
                child: Text(
                  'Utiliser l\'app directement',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
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
