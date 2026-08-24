import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/models/safe_zone.dart';
import '../../../core/repositories/safezone_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../paywall/presentation/paywall_page.dart';
import '../../zones_securite/presentation/widgets/zone_name_icon_step.dart';
import '../../zones_securite/presentation/widgets/zone_place_radius_step.dart';

// Mapping persona → nom et icône par défaut
const _personaDefaults = <String, ({String name, String iconKey})>{
  'children': (name: 'École', iconKey: 'school'),
  'parents': (name: 'Maison', iconKey: 'home'),
  'partner': (name: 'Maison', iconKey: 'home'),
  'friends': (name: 'Point de rendez-vous', iconKey: 'location_on'),
  'family': (name: 'Maison', iconKey: 'home'),
};

class OnboardingZoneCreationPage extends StatefulWidget {
  const OnboardingZoneCreationPage({super.key});

  @override
  State<OnboardingZoneCreationPage> createState() =>
      _OnboardingZoneCreationPageState();
}

class _OnboardingZoneCreationPageState
    extends State<OnboardingZoneCreationPage> {
  late final SafeZoneRepository _repo;
  final _prefs = PrefsService();

  int _step = 0;
  String _name = 'Maison';
  String _iconKey = 'home';
  LatLng _center = const LatLng(3.87000, 11.51500);
  double _radius = 200;
  String? _address;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SafeZoneRepository>();
    _applyPersonaDefaults();
    _initLocation();
  }

  Future<void> _applyPersonaDefaults() async {
    final persona = await _prefs.getOnboardingPersona();
    final defaults = _personaDefaults[persona] ?? _personaDefaults['family']!;
    if (mounted) {
      setState(() {
        _name = defaults.name;
        _iconKey = defaults.iconKey;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) return;

      final svc = LocationService();
      StreamSubscription? sub;
      bool received = false;
      sub = svc.locationStream.listen((pt) {
        if (!mounted) return;
        received = true;
        setState(() => _center = LatLng(pt.latitude, pt.longitude));
        sub?.cancel();
      });

      Timer(const Duration(seconds: 10), () {
        if (!received) sub?.cancel();
      });
    } catch (_) {
      // Position par défaut conservée
    }
  }

  void _next() => setState(() => _step = 1);
  void _prev() => setState(() => _step = 0);

  Future<void> _createZone() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final profile = await _prefs.getUserProfile();
      if (profile?.hasPremiumAccess != true &&
          !SubscriptionService.instance.hasPremiumAccess('unlimited_zones')) {
        final existingZones = await _repo.getSafeZones(forceRefresh: true);
        if (existingZones.isNotEmpty) {
          if (mounted) {
            setState(() => _isCreating = false);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PaywallPage(trigger: 'zone_limit'),
              ),
            );
          }
          return;
        }
      }

      final zone = SafeZone(
        id: '',
        name: _name,
        iconKey: _iconKey,
        center: _center,
        radiusMeters: _radius,
        address: _address,
        memberIds: [],
      );

      await _repo.createSafeZone(zone);
      if (!mounted) return;

      await _prefs.setOnboardingZoneCreated();
      await _prefs.setInitialSetupDone();

      if (mounted) context.go(AppRoutes.onboardingConfirmation);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);

      if (e is InvalidCredentialsException) {
        if (mounted) context.go(AppRoutes.auth);
        return;
      }

      String msg = 'Une erreur est survenue.';
      if (e is NetworkException) msg = 'Vérifiez votre connexion internet.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == 1
            ? IconButton(
                onPressed: _prev,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              )
            : null,
        title: Text(
          _step == 0 ? 'Nomme ta zone' : 'Place ta zone',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        // Indicateur de progression
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 2,
            backgroundColor: scheme.surfaceContainerHighest,
            color: AppColors.teal,
            minHeight: 3,
          ),
        ),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          ZoneNameIconStep(
            initialName: _name,
            initialIconKey: _iconKey,
            onChanged: (n, i) {
              _name = n;
              _iconKey = i;
            },
            onNext: _next,
          ),
          ZonePlaceRadiusStep(
            center: _center,
            radius: _radius,
            address: _address,
            onChanged: (center, radius, address) {
              _center = center;
              _radius = radius;
              _address = address;
            },
            onNext: _createZone,
            onPrev: _prev,
            isCreating: _isCreating,
          ),
        ],
      ),
    );
  }
}
