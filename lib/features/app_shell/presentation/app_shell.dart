import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../../../core/services/app_initialization_service.dart';
import '../../../core/services/global_navigation_service.dart';
import '../../alertes/providers/alert_provider.dart';
import '../providers/navigation_provider.dart';
import '../../home_map/presentation/home_page.dart';
import '../../proches/presentation/proches_tab.dart';
import '../../alertes/presentation/alertes_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _servicesInitialized = false;
  final List<bool> _tabsActivated = [true, false, false];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;
    try {
      log('AppShell: initialisation services...');
      final appInitService = context.read<AppInitializationService>();
      await appInitService.initializeServices(context);
      if (mounted) setState(() => _servicesInitialized = true);
    } catch (e) {
      log('AppShell: erreur init services: $e');
      if (mounted) setState(() => _servicesInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalNavigationService.setContext(context);

    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          GlobalNavigationService.setNavigationProvider(nav);

          // Mark tab as activated on first visit — lazy build
          if (!_tabsActivated[nav.currentIndex]) {
            _tabsActivated[nav.currentIndex] = true;
          }

          final tabs = [
            _tabsActivated[0] ? const MapTab() : const SizedBox.shrink(),
            _tabsActivated[1] ? const ProchesTab() : const SizedBox.shrink(),
            _tabsActivated[2] ? const AlertesPage() : const SizedBox.shrink(),
          ];

          return Scaffold(
            body: IndexedStack(
              index: nav.currentIndex,
              children: tabs,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: nav.currentIndex,
              onDestinationSelected: (i) {
                setState(() => _tabsActivated[i] = true);
                nav.setIndex(i);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Carte',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Proches',
                ),
                NavigationDestination(
                  icon: Consumer<AlertProvider>(
                    builder: (_, alerts, __) => _BadgeIcon(
                      icon: Icons.notifications_outlined,
                      count: alerts.unreadCount,
                    ),
                  ),
                  selectedIcon: Consumer<AlertProvider>(
                    builder: (_, alerts, __) => _BadgeIcon(
                      icon: Icons.notifications,
                      count: alerts.unreadCount,
                    ),
                  ),
                  label: 'Alertes',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
  }
}
