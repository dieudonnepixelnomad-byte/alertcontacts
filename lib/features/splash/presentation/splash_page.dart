import 'dart:async';
import 'dart:math' as math;

import 'package:alertcontacts/core/services/app_initialization_service.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/core/utils/app_logger.dart';
import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/features/auth/providers/auth_state.dart';
import 'package:alertcontacts/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoAc;
  late final AnimationController _taglineAc;
  late final AnimationController _loaderAc;
  late final AnimationController _blobAc;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderSlide;

  Timer? _timeoutTimer;
  bool _navigated = false;
  late final AuthNotifier _authNotifier;

  static const _splashBg = Color(0xFF1E6868);
  static const _totalDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    _authNotifier.addListener(_onAuthStateChanged);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _splashBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Blob rotation (slow, continuous)
    _blobAc = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Logo: scale 0.8→1.0 (300ms ease-out)
    _logoAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoAc, curve: Curves.easeOut),
    );
    _logoFade = CurvedAnimation(parent: _logoAc, curve: Curves.easeOut);

    // Tagline: fade in starting at +150ms
    _taglineAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _taglineFade = CurvedAnimation(parent: _taglineAc, curve: Curves.easeOut);

    // Loader: slide in
    _loaderAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loaderSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderAc, curve: Curves.easeOutCubic),
    );

    _runAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeAuth();
    });
  }

  Future<void> _runAnimations() async {
    await _logoAc.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _taglineAc.forward();
    _loaderAc.forward();
  }

  void _onAuthStateChanged() {
    if (mounted) _handleAuthState(_authNotifier.state);
  }

  Future<void> _initializeAuth() async {
    try {
      await context.read<AppInitializationService>().initializeServices(context);

      if (_authNotifier.isAuthenticated) {
        _handleAuthState(_authNotifier.state);
      } else {
        _authNotifier.silentSignIn();
      }

      // Fix race: if silentSignIn completed synchronously before this line,
      // _navigated is already true — don't arm the timeout.
      if (!_navigated) {
        _timeoutTimer = Timer(const Duration(seconds: 20), () {
          if (mounted) _handleAuthTimeout();
        });
      }
    } on ForcedUpdateException catch (e) {
      AppLogger.i.warning('Forced update required', {'url': e.storeUrl});
      if (mounted) context.go(AppRoutes.forcedUpdate, extra: e.storeUrl);
    } catch (e) {
      AppLogger.i.error('Splash init error', {'error': e.toString()});
      _handleAuthTimeout();
    }
  }

  Future<void> _handleAuthTimeout() async {
    if (!mounted || _navigated) return;
    final prefs = context.read<PrefsService>();

    final hadLoggedIn = await prefs.hasLoggedIn();
    if (!mounted || _navigated) return;

    if (hadLoggedIn) {
      _navigated = true;
      context.go(AppRoutes.appShell);
      return;
    }

    final onboardingDone = await prefs.isOnboardingDone();
    if (!mounted || _navigated) return;
    _navigated = true;
    if (onboardingDone) {
      context.go(AppRoutes.auth);
    } else {
      context.go(AppRoutes.onboardingPersonalization);
    }
  }

  Future<void> _handleAuthState(AuthState state) async {
    _timeoutTimer?.cancel();

    // Ensure minimum splash duration
    final elapsed = _logoAc.lastElapsedDuration ?? Duration.zero;
    final remaining = _totalDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted || _navigated) return;

    if (state.status == AuthStatus.authenticated) {
      _navigated = true;
      context.go(AppRoutes.appShell);
    } else if (state.status == AuthStatus.error ||
        state.status == AuthStatus.unauthenticated) {
      final prefs = context.read<PrefsService>();

      // Si l'utilisateur s'était déjà connecté, on l'envoie à l'app-shell
      // même en cas d'échec réseau — l'app gère le mode offline.
      // Évite le flash de la page login au redémarrage.
      final hadLoggedIn = await prefs.hasLoggedIn();
      if (!mounted || _navigated) return;

      if (hadLoggedIn) {
        _navigated = true;
        context.go(AppRoutes.appShell);
        return;
      }

      final onboardingDone = await prefs.isOnboardingDone();
      if (!mounted || _navigated) return;
      _navigated = true;
      if (onboardingDone) {
        context.go(AppRoutes.auth);
      } else {
        context.go(AppRoutes.onboardingPersonalization);
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _authNotifier.removeListener(_onAuthStateChanged);
    _logoAc.dispose();
    _taglineAc.dispose();
    _loaderAc.dispose();
    _blobAc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: _splashBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated blobs background
            AnimatedBuilder(
              animation: _blobAc,
              builder: (_, __) => CustomPaint(
                painter: _BlobPainter(_blobAc.value),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo + title block
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: const _LogoBlock(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'la sérénité en toutes circonstances',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha:0.60),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Loader bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: AnimatedBuilder(
                      animation: _loaderSlide,
                      builder: (_, __) => SizedBox(
                        width: 100,
                        height: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: _loaderSlide.value < 1.0 ? _loaderSlide.value : null,
                            backgroundColor: Colors.white.withValues(alpha:0.20),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha:0.50),
                            ),
                          ),
                        ),
                      ),
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

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with gradient shader mask
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8C3C), Color(0xFFFF5C7A)],
          ).createShader(bounds),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // App name
        const Text(
          'ALERTCONTACTS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.06 * 22,
          ),
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  const _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Blob 1 — orange, top-right
    _drawBlob(
      canvas,
      center: Offset(
        cx + size.width * 0.35 + math.sin(t * math.pi * 2) * 20,
        cy - size.height * 0.25 + math.cos(t * math.pi * 2) * 15,
      ),
      radius: size.width * 0.45,
      color: const Color(0xFFFF8C3C),
      opacity: 0.35,
    );

    // Blob 2 — green, bottom-left
    _drawBlob(
      canvas,
      center: Offset(
        cx - size.width * 0.30 + math.cos(t * math.pi * 2) * 18,
        cy + size.height * 0.30 + math.sin(t * math.pi * 2 + 1) * 12,
      ),
      radius: size.width * 0.40,
      color: const Color(0xFF32D282),
      opacity: 0.28,
    );

    // Blob 3 — light teal, center
    _drawBlob(
      canvas,
      center: Offset(
        cx + math.sin(t * math.pi * 2 + 2) * 10,
        cy - size.height * 0.10 + math.cos(t * math.pi * 2 + 2) * 10,
      ),
      radius: size.width * 0.30,
      color: const Color(0xFF7ECECE),
      opacity: 0.15,
    );
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha:opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
