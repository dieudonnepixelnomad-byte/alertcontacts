import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

class OnboardingSlidesPage extends StatefulWidget {
  const OnboardingSlidesPage({super.key});

  @override
  State<OnboardingSlidesPage> createState() => _OnboardingSlidesPageState();
}

class _OnboardingSlidesPageState extends State<OnboardingSlidesPage> {
  final _pageController = PageController();
  int _currentIndex = 0;

  static const _slides = [
    _Slide(
      icon: Icons.location_on_outlined,
      iconColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      title: 'Suis tes proches\nen temps réel',
      description:
          'Vois où se trouvent tes proches sur la carte, en direct, même quand tu es loin.',
    ),
    _Slide(
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFF8C3C),
      backgroundColor: Color(0xFFFFF3E8),
      title: 'Reçois des alertes\ninstantanées',
      description:
          'Sois notifié dès qu\'un proche arrive ou quitte une zone, et reçois les alertes de ta communauté.',
    ),
    _Slide(
      icon: Icons.shield_outlined,
      iconColor: AppColors.success,
      backgroundColor: Color(0xFFECFDF5),
      title: 'Crée des zones\nde sécurité',
      description:
          'Définis des endroits importants — école, maison, travail — et sois alerté à chaque passage.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    PrefsService().setOnboardingSlidesSeen();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    AnalyticsService().logOnboardingSlidesCompleted();
    context.go(AppRoutes.onboardingInvitation);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Passer',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;

  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.backgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              slide.icon,
              size: 56,
              color: slide.iconColor,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
