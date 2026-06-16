import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class OnboardingNotificationPermissionPage extends StatefulWidget {
  const OnboardingNotificationPermissionPage({super.key});

  @override
  State<OnboardingNotificationPermissionPage> createState() =>
      _OnboardingNotificationPermissionPageState();
}

class _OnboardingNotificationPermissionPageState
    extends State<OnboardingNotificationPermissionPage> {
  final _prefs = PrefsService();
  bool _isRequesting = false;

  String get _inviteeName => '';

  Future<void> _requestAndContinue() async {
    setState(() => _isRequesting = true);
    final granted = await PermissionsService.requestNotificationPermission();
    AnalyticsService().logPermissionResult(type: 'notification', granted: granted);
    await _prefs.setOnboardingNotifPermAsked();
    // R3 : pas de permission location dans l'onboarding — aller directement à la création de zone
    if (mounted) context.go(AppRoutes.onboardingZoneCreation);
  }

  void _skip() {
    AnalyticsService().logPermissionResult(type: 'notification', granted: false);
    _prefs.setOnboardingNotifPermAsked();
    // R3 : pas de permission location dans l'onboarding — aller directement à la création de zone
    context.go(AppRoutes.onboardingZoneCreation);
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

              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 52,
                  color: AppColors.teal,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                _inviteeName.isNotEmpty
                    ? 'Sois alerté(e) dès que $_inviteeName arrive ou part'
                    : 'Sois alerté(e) en temps réel',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Sans notification, tu ne sauras pas quand ton proche entre dans une zone — même si l\'app tourne en arrière-plan.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              FilledButton(
                onPressed: _isRequesting ? null : _requestAndContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Activer les alertes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: _skip,
                child: Text(
                  'Pas maintenant',
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
