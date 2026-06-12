import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class OnboardingLocationPermissionPage extends StatefulWidget {
  const OnboardingLocationPermissionPage({super.key});

  @override
  State<OnboardingLocationPermissionPage> createState() =>
      _OnboardingLocationPermissionPageState();
}

class _OnboardingLocationPermissionPageState
    extends State<OnboardingLocationPermissionPage> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyGranted();
  }

  Future<void> _checkIfAlreadyGranted() async {
    final granted = await PermissionsService.isLocationPermissionGranted();
    if (granted && mounted) {
      context.go(AppRoutes.onboardingZoneCreation);
    }
  }

  Future<void> _requestAndContinue() async {
    setState(() => _isRequesting = true);
    await PermissionsService.requestLocationPermission();
    if (mounted) context.go(AppRoutes.onboardingZoneCreation);
  }

  void _skip() => context.go(AppRoutes.onboardingZoneCreation);

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
                  Icons.location_on_outlined,
                  size: 52,
                  color: AppColors.teal,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Pour créer ta première zone de sécurité',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'AlertContacts a besoin de ta position pour centrer la carte sur toi. Ta localisation n\'est jamais partagée sans ton accord.',
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
                        'Localiser ma position',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: _skip,
                child: Text(
                  'Entrer une adresse manuellement',
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
