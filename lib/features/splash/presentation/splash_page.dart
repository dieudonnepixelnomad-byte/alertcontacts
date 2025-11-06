import 'dart:async';
import 'dart:developer';

import 'package:alertcontacts/core/services/app_initialization_service.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/features/auth/providers/auth_state.dart';
import 'package:alertcontacts/features/splash/presentation/forced_update_page.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timeoutTimer;
  late final AuthNotifier authNotifier;

  @override
  void initState() {
    super.initState();

    // Récupération de l'instance de AuthNotifier
    authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    // Ajouter le listener pour les changements d'état d'authentification
    authNotifier.addListener(_onAuthStateChanged);

    // Status bar & nav bar lisibles sur fond sombre
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF006970),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));

    _ac.forward();

    log('SplashPage initState');

    // Initialiser l'authentification une seule fois dans initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAuth();
      }
    });
  }

  void _onAuthStateChanged() {
    if (mounted) {
      _handleAuthState(authNotifier.state);
    }
  }

  void _initializeAuth() async {
    log('SplashPage _initializeAuth');

    try {
      // Lancer l'initialisation des services (qui inclut la vérification de la version)
      await context.read<AppInitializationService>().initializeServices(context);

      // Si l'initialisation réussit, continuer avec la logique d'authentification
      if (authNotifier.isAuthenticated) {
        log("SplashPage _initializeAuth: Utilisateur déjà authentifié");
        _handleAuthState(authNotifier.state);
      } else {
        log("SplashPage _initializeAuth: Tentative d'authentification silencieuse");
        authNotifier.silentSignIn();
      }

      // Timer de sécurité pour éviter un blocage infini
      _timeoutTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) {
          debugPrint('SplashPage _handleAuthTimeout timeout');
          _handleAuthTimeout();
        }
      });
    } on ForcedUpdateException catch (e) {
      log("SplashPage: Mise à jour forcée requise. URL: ${e.storeUrl}");
      if (mounted) {
        // Remplacer la page actuelle par la page de mise à jour forcée
        context.go(AppRoutes.forcedUpdate, extra: e.storeUrl);
      }
    } catch (e) {
      log("SplashPage: Erreur inattendue lors de l'initialisation: $e");
      // En cas d'autre erreur, on peut décider de rediriger vers une page d'erreur
      // ou de tenter la redirection par défaut.
      _handleAuthTimeout();
    }
  }

  void _handleAuthTimeout() async {
    if (!mounted) return;

    final prefs = context.read<PrefsService>();
    final onBoardingDone = await prefs.isOnboardingDone();

    if (onBoardingDone) {
      log("SplashPage _handleAuthTimeout: Onboarding terminé, redirection vers la connexion");
      if (mounted) {
        context.go(AppRoutes.auth);
      }
    } else {
      log("SplashPage _handleAuthTimeout: Onboarding non terminé, redirection vers l'onboarding");
      if (mounted) {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  void _handleAuthState(AuthState state) async {
    log('SplashPage _handleAuthState: $state');
    _timeoutTimer?.cancel();

    if (state.status == AuthStatus.authenticated) {
      log('SplashPage _handleAuthState: Authenticated');
      if (mounted) {
        context.go(AppRoutes.appShell);
      }
    } else if (state.status == AuthStatus.error || state.status == AuthStatus.unauthenticated) {
      log('SplashPage _handleAuthState: AuthError or AuthUnauthenticated');
      final prefs = context.read<PrefsService>();
      final onBoardingDone = await prefs.isOnboardingDone();

      if (onBoardingDone) {
        log("SplashPage _handleAuthState: Onboarding terminé, redirection vers la connexion");
        if (mounted) {
          context.go(AppRoutes.auth);
        }
      } else {
        log("SplashPage _handleAuthState: Onboarding non terminé, redirection vers l'onboarding");
        if (mounted) {
          context.go(AppRoutes.onboarding);
        }
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    authNotifier.removeListener(_onAuthStateChanged);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs de la charte
    const teal = Color(0xFF006970);

    return Scaffold(
      backgroundColor: teal,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: teal,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) IMAGE DE FOND
            //    Si l'image manque ou échoue → fallback gradient uni (voir errorBuilder)
            Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        teal,
                        Color(
                          0xFF0A7F87,
                        ), // teal plus clair pour un léger relief
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2) OVERLAY DÉGRADÉ (lisibilité + tonalité de marque)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.15),
                  radius: 1.0,
                  colors: [
                    teal.withOpacity(0.10),
                    Colors.black.withOpacity(0.25), // assombrit les bords
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // 4) CONTENU (logo/nom + baseline + loader) avec animation
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      children: [
                        // Nom / Logo centré
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 100,
                                height: 100,
                              ),
                              SizedBox(height: 16),
                              _BrandTitle(),
                            ],
                          ),
                        ),
                        // Baseline + loader en bas
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 36,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Votre sécurité. Votre sérénité.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  // fontFamily: 'Roboto', // active si tu as la font
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de marque (remplace par ton logo si tu préfères)
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ALERTCONTACTS',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        // fontFamily: 'Montserrat', // active si tu as la font
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }
}
