// lib/features/shell/presentation/app_shell.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer';
import '../../../core/services/prefs_service.dart';
import '../../../core/widgets/navbar_drawer.dart';
import '../../../core/services/app_initialization_service.dart';
import '../../../core/services/global_navigation_service.dart';
import '../providers/navigation_provider.dart';
import '../../home_map/presentation/home_page.dart';
import '../../zones/pages/unified_zones_page.dart';
import '../../proches/presentation/proches_tab.dart';
import '../../activities/presentation/activity_tab.dart';
import '../widgets/first_launch_tooltip.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _servicesInitialized = false;
  bool _showTooltip = false;
  bool _emailVerified = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkFirstLaunch();
    _checkEmailVerification();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = PrefsService();
    final shown = await prefs.isFirstLaunchTooltipShown();
    if (!shown && mounted) setState(() => _showTooltip = true);
  }

  void _checkEmailVerification() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified && user.providerData.any((p) => p.providerId == 'password')) {
      if (mounted) setState(() => _emailVerified = false);
    }
  }

  Future<void> _dismissTooltip() async {
    final prefs = PrefsService();
    await prefs.setFirstLaunchTooltipShown();
    if (mounted) setState(() => _showTooltip = false);
  }

  /// Initialise automatiquement tous les services de surveillance
  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;

    try {
      print('🚀 AppShell: Initialisation des services de surveillance...');
      log('AppShell: Initialisation des services de surveillance...');
      final appInitService = context.read<AppInitializationService>();
      await appInitService.initializeServices(context);
      
      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
        print('✅ AppShell: Services de surveillance initialisés avec succès');
        log('AppShell: Services de surveillance initialisés avec succès');
      }
    } catch (e) {
      print('❌ AppShell: Erreur lors de l\'initialisation des services: $e');
      log('AppShell: Erreur lors de l\'initialisation des services: $e');
      // Ne pas bloquer l'interface utilisateur en cas d'erreur
      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser le contexte global pour la navigation depuis les notifications
    GlobalNavigationService.setContext(context);
    
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
          // Passer le provider au service global
          GlobalNavigationService.setNavigationProvider(navigationProvider);
          final _tabs = [
            const MapTab(), // Carte + bottom sheet
            const UnifiedZonesPage(), // Liste zones unifiée
            const ProchesTab(), // Liste proches
            const ActivityTab(), // Timeline
          ];

          final _appBarTitles = [
            'AlertContact',
            'Mes Zones',
            'Mes proches',
            'Activité',
          ];

          return Scaffold(
            drawer: const NavbarDrawer(),
            appBar: AppBar(
              title: Text(_appBarTitles[navigationProvider.currentIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    context.go('/help');
                  },
                  tooltip: 'Guide d\'utilisation',
                ),
              ],
            ),
            body: Stack(
              children: [
                IndexedStack(
                  index: navigationProvider.currentIndex,
                  children: _tabs,
                ),
                if (_showTooltip)
                  FirstLaunchTooltip(onDismiss: _dismissTooltip),
                if (!_emailVerified)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: MaterialBanner(
                      content: const Text(
                        'Vérifie ton adresse e-mail pour sécuriser ton compte.',
                        style: TextStyle(fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                            if (context.mounted) setState(() => _emailVerified = true);
                          },
                          child: const Text('Renvoyer'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _emailVerified = true),
                          child: const Text('Ignorer'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationProvider.currentIndex,
              onDestinationSelected: navigationProvider.setIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Carte',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shield_outlined),
                  selectedIcon: Icon(Icons.shield),
                  label: 'Zones',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group),
                  label: 'Proches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: 'Activité',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
