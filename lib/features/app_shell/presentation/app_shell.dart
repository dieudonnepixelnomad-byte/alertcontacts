// lib/features/shell/presentation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer';
import '../../../core/widgets/navbar_drawer.dart';
import '../../../core/services/app_initialization_service.dart';
import '../../../core/services/global_navigation_service.dart';
import '../providers/navigation_provider.dart';
import '../../home_map/presentation/home_page.dart';
import '../../zones/pages/unified_zones_page.dart';
import '../../proches/presentation/proches_tab.dart';
import '../../activities/presentation/activity_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
            body: IndexedStack(
              index: navigationProvider.currentIndex,
              children: _tabs,
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
