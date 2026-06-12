import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final _prefs = PrefsService();
  String? _selected;

  static const _personas = [
    (key: 'children', label: 'Mes enfants', emoji: '👶'),
    (key: 'parents', label: 'Mes parents', emoji: '👴'),
    (key: 'partner', label: 'Mon/ma conjoint(e)', emoji: '❤️'),
    (key: 'friends', label: 'Mes amis', emoji: '👫'),
    (key: 'family', label: 'Toute ma famille', emoji: '🏠'),
  ];

  Future<void> _continue(String? persona) async {
    final p = persona ?? 'family';
    AnalyticsService().logOnboardingPersonaSelected(p);
    await _prefs.setOnboardingPersona(p);
    await _prefs.setUserSetupDone();
    if (mounted) context.go(AppRoutes.onboardingInvitation);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              Text(
                'Qui veux-tu protéger en priorité ?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'On personnalise AlertContacts pour toi.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 32),

              // Options
              Expanded(
                child: ListView(
                  children: _personas.map((p) {
                    final isSelected = _selected == p.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = p.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.teal.withValues(alpha: 0.08)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.teal
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(p.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                p.label,
                                style: text.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.teal
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.teal),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed:
                    _selected != null ? () => _continue(_selected) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.teal.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => _continue(null),
                child: Text(
                  'Je verrai plus tard',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
