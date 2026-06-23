import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final _prefs = PrefsService();
  String? _selected;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logOnboardingStarted();
  }

  static const _profiles = [
    (key: 'children', label: 'Mes enfants', emoji: '👶'),
    (key: 'parents', label: 'Mes parents', emoji: '👴'),
    (key: 'partner', label: 'Mon conjoint(e)', emoji: '❤️'),
    (key: 'self', label: 'Moi-même', emoji: '🧘'),
  ];

  Future<void> _continue(String? profile) async {
    final p = profile ?? 'self';
    AnalyticsService().logOnboardingPersonaSelected(p);
    await _prefs.setOnboardingPersona(p);
    await _prefs.setUserSetupDone();
    if (mounted) context.go(AppRoutes.appShell);
  }

  Future<void> _skip() async {
    if (mounted) context.go(AppRoutes.appShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              Text(
                'Tu protèges qui ?',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'On personnalise l\'app pour toi',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray600,
                ),
              ),

              const SizedBox(height: 40),

              // 2×2 grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _profiles.map((p) {
                    final isSelected = _selected == p.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = p.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              p.label,
                              textAlign: TextAlign.center,
                              style:
                                  AppTypography.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray900,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 6),
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected != null ? () => _continue(_selected) : null,
                  child: const Text('Continuer'),
                ),
              ),

              const SizedBox(height: 4),

              TextButton(
                onPressed: _skip,
                child: Text(
                  'Passer cette étape',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
