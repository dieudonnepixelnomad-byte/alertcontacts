import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/unified_alert_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';

enum _DangerType { agression, vol, harcelement, autre }

extension _DangerTypeLabel on _DangerType {
  String get label {
    switch (this) {
      case _DangerType.agression:
        return 'Agression';
      case _DangerType.vol:
        return 'Vol';
      case _DangerType.harcelement:
        return 'Harcèlement';
      case _DangerType.autre:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case _DangerType.agression:
        return Icons.warning_rounded;
      case _DangerType.vol:
        return Icons.money_off_rounded;
      case _DangerType.harcelement:
        return Icons.people_alt_rounded;
      case _DangerType.autre:
        return Icons.error_outline_rounded;
    }
  }

  String get voiceLabel {
    switch (this) {
      case _DangerType.agression:
        return 'agression';
      case _DangerType.vol:
        return 'vol';
      case _DangerType.harcelement:
        return 'harcèlement';
      case _DangerType.autre:
        return 'danger';
    }
  }
}

// Position de fallback (Yaoundé, Cameroun)
const _defaultPosition = LatLng(3.8700, 11.5150);

class AhaSandboxPage extends StatefulWidget {
  const AhaSandboxPage({super.key});

  @override
  State<AhaSandboxPage> createState() => _AhaSandboxPageState();
}

class _AhaSandboxPageState extends State<AhaSandboxPage>
    with SingleTickerProviderStateMixin {
  final _prefsService = PrefsService();
  GoogleMapController? _mapController;

  LatLng _center = _defaultPosition;
  double _radius = 100.0;
  _DangerType _selectedType = _DangerType.agression;
  bool _alertTriggered = false;
  bool _locationRequested = true;
  bool _showPulseOverlay = false;
  bool _isAlertLoading = false;
  bool _isLocating = false;
  StreamSubscription? _locationSub;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logOnboardingSandboxViewed();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pulseTimer?.cancel();
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    setState(() => _locationRequested = true);
    final granted = await PermissionsService.requestLocationPermission();
    if (!granted || !mounted) return;
    _startLocationStream();
  }

  void _startLocationStream() {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final svc = LocationService();
    bool received = false;
    _locationSub = svc.locationStream.listen((pt) {
      if (!mounted) return;
      received = true;
      final pos = LatLng(pt.latitude, pt.longitude);
      setState(() {
        _center = pos;
        _isLocating = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
      _locationSub?.cancel();
    });

    Timer(const Duration(seconds: 10), () {
      if (!received) {
        _locationSub?.cancel();
        if (mounted) setState(() => _isLocating = false);
      }
    });
  }

  Future<void> _triggerAlert() async {
    if (_isAlertLoading) return;
    AnalyticsService().logOnboardingAhaMomentTriggered(
      _selectedType.voiceLabel,
    );
    setState(() => _isAlertLoading = true);

    final service = UnifiedAlertService();
    await service.initialize();
    await service.triggerAlert(
      AlertConfig(
        type: AlertType.dangerZone,
        voiceMessage:
            'Attention. Zone de ${_selectedType.voiceLabel} détectée à proximité. Restez vigilant.',
        vibrationIntensity: VibrationIntensity.critical,
        enableVoice: true,
        enableVibration: true,
      ),
    );

    if (!mounted) return;
    setState(() {
      _alertTriggered = true;
      _showPulseOverlay = true;
      _isAlertLoading = false;
    });

    _pulseController.repeat(reverse: true);
    _pulseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showPulseOverlay = false);
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  Future<void> _continue() async {
    await _prefsService.setAhaSandboxSeen();
    if (mounted) context.go(AppRoutes.onboardingCelebration);
  }

  void _skip() {
    AnalyticsService().logOnboardingSandboxSkipped();
    context.go(AppRoutes.auth);
  }

  Set<Circle> get _circles => {
    Circle(
      circleId: const CircleId('sandbox_zone'),
      center: _center,
      radius: _radius,
      fillColor: AppColors.alert.withValues(alpha: 0.2),
      strokeColor: AppColors.alert,
      strokeWidth: 2,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              // Bandeau haut
              Container(
                width: double.infinity,
                color: AppColors.teal,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Place une zone fictive et teste l\'alerte réelle',
                        style: text.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Passer'),
                    ),
                  ],
                ),
              ),

              // Pré-demande localisation (si pas encore demandée)
              if (!_locationRequested)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pour placer la zone autour de toi',
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Aucune donnée n\'est envoyée.',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _requestLocation,
                        child: const Text(
                          'Utiliser\nma position',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

              // Badge ZONE TEST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alert.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.alert),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 14,
                            color: AppColors.alert,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ZONE TEST — non publiée',
                            style: text.labelSmall?.copyWith(
                              color: AppColors.alert,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Carte Google Maps
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 16,
                        ),
                        onMapCreated: (c) => _mapController = c,
                        circles: _circles,
                        myLocationEnabled: _locationRequested,
                        myLocationButtonEnabled: _locationRequested,
                        zoomControlsEnabled: false,
                        onTap: (pos) => setState(() => _center = pos),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Overlay rouge pulse lors du déclenchement
          if (_showPulseOverlay)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => IgnorePointer(
                child: Container(
                  color: Colors.red.withValues(
                    alpha: 0.3 * _pulseAnimation.value,
                  ),
                ),
              ),
            ),

          // Panel bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slider rayon
                  Row(
                    children: [
                      Text(
                        'Rayon',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 50,
                          max: 500,
                          divisions: 9,
                          label: '${_radius.round()}m',
                          activeColor: AppColors.teal,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ),
                      Text('${_radius.round()}m', style: text.labelMedium),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Sélecteur type de danger
                  Row(
                    children: _DangerType.values.map((type) {
                      final selected = type == _selectedType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.alert.withValues(alpha: 0.12)
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.alert
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type.icon,
                                  size: 20,
                                  color: selected
                                      ? AppColors.alert
                                      : scheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  type.label,
                                  textAlign: TextAlign.center,
                                  style: text.labelSmall?.copyWith(
                                    color: selected
                                        ? AppColors.alert
                                        : scheme.onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Bouton principal
                  if (!_alertTriggered)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isAlertLoading ? null : _triggerAlert,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.alert,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isAlertLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.notifications_active),
                        label: Text(
                          _isAlertLoading
                              ? 'Déclenchement...'
                              : 'Déclencher l\'alerte',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
