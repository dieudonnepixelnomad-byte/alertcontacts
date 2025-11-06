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
  final prefsService = PrefsService();

  List<_SlideData> _getSlides(BuildContext context) {
    final l10n = context.l10n;
    return [
      _SlideData(
        title: l10n.onBoardingSlide_title_1,
        body: l10n.onBoardingSlide_body_1,
        assetName: 'assets/illustrations/intro.png',
      ),
      _SlideData(
        title: l10n.onBoardingSlide_title_2,
        body: l10n.onBoardingSlide_body_2,
        assetName: 'assets/illustrations/danger.png',
      ),
      _SlideData(
        title: l10n.onBoardingSlide_title_3,
        body: l10n.onBoardingSlide_body_3,
        assetName: 'assets/illustrations/safe.png',
      ),
      _SlideData(
        title: l10n.onBoardingSlide_title_4,
        body: l10n.onBoardingSlide_body_4,
        assetName: 'assets/illustrations/privacy.png',
      ),
    ];
  }

  void _next() {
    if (_index < _getSlides(context).length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() {
    prefsService.setOnboardingDone().then((_) {
      if (mounted) {
        context.go(AppRoutes.permissionLocation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Barre actions (Passer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(context.l10n.onBoardingSkip),
                  ),
                  const Spacer(),
                  // compteur x/4 (option)
                  Text(
                    '${_index + 1}/${_getSlides(context).length}',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _getSlides(context).length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (ctx, i) =>
                    _OnboardingSlide(data: _getSlides(context)[i]),
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  _Dots(count: _getSlides(context).length, index: _index),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      _index == _getSlides(context).length - 1
                          ? context.l10n.onBoardingStart
                          : context.l10n.onBoardingNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.onSurface;
    final inactive = active.withOpacity(0.25);

    return Row(
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 6),
          height: 8,
          width: isActive ? 22 : 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration (facultative)
          if (data.assetName != null) ...[
            SizedBox(
              height: 260,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset(data.assetName!),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Titre
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: text.displayLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Corps
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              fontSize: 15,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String body;
  final String? assetName;

  const _SlideData({required this.title, required this.body, this.assetName});
}
