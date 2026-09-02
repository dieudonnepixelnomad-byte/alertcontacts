import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/app_initialization_service.dart';
import '../../../core/services/global_navigation_service.dart';
import '../../alertes/services/consent_service.dart';
import '../../alertes/providers/alert_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/navigation_provider.dart';
import '../../home_map/presentation/home_page.dart';
import '../../proches/presentation/proches_tab.dart';
import '../../alertes/presentation/alertes_page.dart';
import '../../traceurs/presentation/traceurs_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _servicesInitialized = false;
  final List<bool> _tabsActivated = [true, false, false, false];

  @override
  void initState() {
    super.initState();
    AnalyticsService().logAppShellReached();
    _initializeServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askAnalyticsConsentIfNeeded();
    });
  }

  Future<void> _askAnalyticsConsentIfNeeded() async {
    if (!mounted) return;
    final consentService = ConsentService();
    if (await consentService.hasAnalyticsConsentDecision()) return;
    if (!mounted) return;

    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Améliorer AlertContacts'),
        content: const Text(
          'Acceptez-vous de partager des données d’usage non sensibles pour nous aider à améliorer les parcours, corriger les abandons et mesurer les fonctionnalités utiles ?\n\n'
          'Aucune position GPS précise, aucun nom de proche, aucun email et aucun identifiant matériel de traceur ne sera envoyé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Refuser'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    final analyticsConsent = granted ?? false;
    await consentService.setAnalyticsConsent(analyticsConsent);

    try {
      if (mounted) {
        await context.read<ProfileProvider>().updateConsents(
          analyticsConsent: analyticsConsent,
        );
      }
    } catch (e) {
      log('AppShell: erreur synchronisation consentement analytics: $e');
    }
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;
    try {
      log('AppShell: initialisation services...');
      final appInitService = context.read<AppInitializationService>();
      await appInitService.initializeServices(context);

      // Initialise AlertProvider : charge acquittements, init NotificationManager,
      // et démarre le timer de polling périodique des alertes communautaires.
      if (mounted) {
        log('AppShell: initialisation AlertProvider...');
        await context.read<AlertProvider>().initialize();
        log('AppShell: AlertProvider initialisé');
      }

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
            _tabsActivated[3] ? const TraceursTab() : const SizedBox.shrink(),
          ];

          return Scaffold(
            body: IndexedStack(index: nav.currentIndex, children: tabs),
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
                const NavigationDestination(
                  icon: Icon(Icons.gps_fixed_outlined),
                  selectedIcon: Icon(Icons.gps_fixed),
                  label: 'Traceurs',
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
    return Badge(label: Text(count > 99 ? '99+' : '$count'), child: Icon(icon));
  }
}
