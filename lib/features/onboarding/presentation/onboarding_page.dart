import 'package:alertcontacts/core/services/analytics_service.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/utils/l10n_helper.dart';
import 'package:alertcontacts/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;
  final _prefs = PrefsService();

  @override
  void initState() {
    super.initState();
    AnalyticsService().logOnboardingSlideViewed(1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  List<_SlideData> _buildSlides(BuildContext context) {
    final l = context.l10n;
    return [
      _SlideData(
        title: l.onBoardingSlide_title_1,
        body: l.onBoardingSlide_body_1,
        illustration: const _Slide1Illustration(),
        bgColor: const Color(0xFF16213E),
        textColor: Colors.white,
        illustrationSemantics:
            'Deux situations d\'anxiété : un parent qui attend des nouvelles, une personne seule dans une rue sombre',
        analyticsEvent: 'onboarding_slide_1_viewed',
      ),
      _SlideData(
        title: l.onBoardingSlide_title_2,
        body: l.onBoardingSlide_body_2,
        illustration: const _Slide2Illustration(),
        bgColor: const Color(0xFF0D1B2A),
        textColor: Colors.white,
        illustrationSemantics:
            'Téléphone affichant une carte avec une zone de danger rouge et une notification d\'alerte',
        analyticsEvent: 'onboarding_slide_2_viewed',
      ),
      _SlideData(
        title: l.onBoardingSlide_title_3,
        body: l.onBoardingSlide_body_3,
        illustration: const _Slide3Illustration(),
        bgColor: const Color(0xFFFFF8F0),
        textColor: const Color(0xFF1A1A2E),
        illustrationSemantics:
            'Notification indiquant qu\'un proche est arrivé, parent soulagé qui regarde son téléphone',
        analyticsEvent: 'onboarding_slide_3_viewed',
      ),
    ];
  }

  void _next() {
    final slides = _buildSlides(context);
    if (_index < slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AnalyticsService().logOnboardingSlidesCompleted();
      _finish();
    }
  }

  void _skip() {
    AnalyticsService().logOnboardingSlidesSkipped(_index + 1);
    _finish();
  }

  void _finish() {
    _prefs.setOnboardingPhase(1).then((_) {
      if (mounted) context.go(AppRoutes.onboardingSandbox);
    });
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides(context);
    final currentBg = slides[_index].bgColor;
    final isLastSlide = _index == slides.length - 1;

    return Scaffold(
      backgroundColor: currentBg,
      body: Stack(
        children: [
          // Full-screen PageView
          PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              AnalyticsService().logOnboardingSlideViewed(i + 1);
            },
            itemBuilder: (ctx, i) => _OnboardingSlide(
              data: slides[i],
              isLast: i == slides.length - 1,
              onNext: _next,
              onSkip: _skip,
            ),
          ),

          // Overlay: progress dots (centered) + Passer button (right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  // Left spacer mirrors the Passer button to keep dots truly centered
                  Expanded(child: SizedBox()),
                  _Dots(
                    count: slides.length,
                    index: _index,
                    onTap: (i) => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: isLastSlide
                          ? const SizedBox.shrink()
                          : Semantics(
                              label: 'Passer l\'introduction',
                              child: TextButton(
                                onPressed: _skip,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Colors.white.withValues(alpha: 0.7),
                                  minimumSize: const Size(48, 48),
                                ),
                                child: Text(
                                  context.l10n.onBoardingSkip,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide widget ────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _OnboardingSlide({
    required this.data,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: data.bgColor,
      child: Column(
        children: [
          // Illustration — 60% of screen
          Expanded(
            flex: 6,
            child: Semantics(
              label: data.illustrationSemantics,
              child: data.illustration,
            ),
          ),

          // Text + CTA — 40%
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: data.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.body,
                    style: TextStyle(
                      color: data.textColor.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA
                  if (isLast) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        label: l.onBoardingTryNow,
                        child: FilledButton(
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l.onBoardingTryNow,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          l.onBoardingSkip,
                          style: TextStyle(
                            color: data.textColor.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: l.onBoardingNext,
                        child: FilledButton(
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: const StadiumBorder(),
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(
                            l.onBoardingNext,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress dots ───────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final void Function(int) onTap;

  const _Dots({
    required this.count,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 22 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String body;
  final Widget illustration;
  final Color bgColor;
  final Color textColor;
  final String illustrationSemantics;
  final String analyticsEvent;

  const _SlideData({
    required this.title,
    required this.body,
    required this.illustration,
    required this.bgColor,
    required this.textColor,
    required this.illustrationSemantics,
    required this.analyticsEvent,
  });
}

// ─── Illustration widgets ────────────────────────────────────────────────────

/// Slide 1 — Split screen: anxious parent (warm) vs person alone in dark street (cold)
class _Slide1Illustration extends StatelessWidget {
  const _Slide1Illustration();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: warm interior — parent waiting anxiously
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D1B0E), Color(0xFF3D2410)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warm lamp glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF9D4D).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9D4D).withValues(alpha: 0.2),
                          blurRadius: 36,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.light_mode_rounded,
                      color: Color(0xFFFFBB77),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFFFBB77),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  // Phone showing 22:47
                  Container(
                    width: 60,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF9D4D).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '22:47',
                      style: TextStyle(
                        color: Color(0xFFFFBB77),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Divider
        Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
        // Right: cold urban — person walking alone at night
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1424), Color(0xFF16213E)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Street lamp
                  Container(
                    width: 3,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.07),
                          blurRadius: 28,
                          spreadRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.directions_walk_rounded,
                    color: Color(0xFFB0C4DE),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  // Road dashes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 18,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 2 — Phone with map, danger zone + real-time notification
class _Slide2Illustration extends StatelessWidget {
  const _Slide2Illustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer vibration rings (behind phone)
            ...[1.35, 1.55].map(
              (s) => Container(
                width: 180 * s,
                height: 320 * s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28 * s),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.06 / s),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Phone mockup
            Container(
              width: 180,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Map background (street grid)
                    Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
                    // Danger zone (red circle)
                    Positioned(
                      top: 90,
                      left: 22,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.22),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // User position dot (safely outside the danger zone)
                    Positioned(
                      top: 148,
                      left: 112,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Notification banner
                    Positioned(
                      top: 10,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('⚠️', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Zone d\'agression signalée à 180m',
                                style: TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A4A)
      ..strokeWidth = 1;

    // Horizontal streets
    for (var y = 0.0; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical streets
    for (var x = 0.0; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Fill blocks with slightly lighter color
    final blockPaint = Paint()..color = const Color(0xFF152535);
    final streets = size.height / 6;
    final vstreets = size.width / 4;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            col * vstreets + 1,
            row * streets + 1,
            vstreets - 2,
            streets - 2,
          ),
          blockPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 3 — Notification + relieved parent (warm light theme)
class _Slide3Illustration extends StatelessWidget {
  const _Slide3Illustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF0E0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notification card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✓ Léa est arrivée à l\'école',
                          style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Il y a 2 minutes',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Relieved parent face
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE0C0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9D4D).withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sentiment_satisfied_alt_rounded,
                color: Color(0xFFE07030),
                size: 52,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Soulagé.',
              style: TextStyle(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.45),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
