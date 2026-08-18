import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';

import '../../../core/models/contact_relation.dart';
import '../../../core/models/danger_zone.dart';
import '../../../core/enums/incident_type.dart';
import '../../../core/providers/map_type_notifier.dart';
import '../../../core/services/api_location_service.dart';
import '../../../core/services/contact_rtdb_service.dart';
import '../../../core/services/paywall_trigger_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../shared/widgets/gps_imprecise_banner.dart';
import '../../../shared/widgets/map_type_toggle_button.dart';
import '../../../shared/widgets/location_permission_overlay.dart';
import '../../../shared/widgets/low_battery_banner.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/offline_cache_card.dart';
import '../../zones/presentation/zones_panel.dart';
import '../../../features/paywall/presentation/paywall_page.dart';
import 'invisible_mode_sheet.dart';
import '../../../core/models/zone.dart' as zone_models;
import '../../../core/repositories/dangerzone_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';
import '../../../theme/colors.dart';
import '../../alertes/presentation/incident_detail_sheet.dart';
import '../../alertes/providers/alert_provider.dart';
import '../../alertes/providers/incident_provider.dart';
import '../../trajets/presentation/route_preview_page.dart';
import '../../trajets/presentation/route_search_page.dart';
import '../../trajets/presentation/widgets/active_route_banner.dart';
import '../../trajets/presentation/widgets/route_search_bar.dart';
import '../../trajets/providers/route_provider.dart';
import '../../app_shell/providers/navigation_provider.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../proches/providers/relationship_provider.dart';
import '../../zones/providers/zones_notifier.dart';
import 'map_viewport_cache.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with WidgetsBindingObserver {
  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(48.8566, 2.3522),
    zoom: 14.0,
  );

  gmaps.GoogleMapController? _controller;
  gmaps.LatLng? _currentPosition;
  bool _loadingLocation = false;
  double _currentZoom = 14.0;
  Timer? _cameraDebounceTimer;
  late final LocationService _locationService;
  late final AlertProvider _alertProvider;
  bool _alertListenerAttached = false;
  bool _dependenciesInitialized = false;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectivitySubscription;

  // Connectivity
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];

  // Sélection
  DangerZone? _selectedDanger;
  zone_models.Zone? _selectedSafe;

  // Danger zone markers
  Set<gmaps.Marker> _dangerMarkers = {};
  List<DangerZone> _dangerZones = [];

  // Cache viewport LRU
  final MapViewportCache _viewportCache = MapViewportCache();
  String? _lastViewportKey;
  bool _viewportLoading = false;
  gmaps.CameraPosition? _lastCameraPosition;

  // Suivi création d'alertes pour invalidation cache
  int _lastAlertCreatedCount = 0;

  // Caméra
  bool _cameraMovedToZone = false;

  // Mode invisible
  bool _invisibleActive = false;
  DateTime? _invisibleUntil;

  // Custom contact markers cache
  final Map<String, gmaps.BitmapDescriptor> _contactMarkerIcons = {};

  // Les pictogrammes des incidents sont générés une fois par catégorie. On ne
  // retombe volontairement pas sur `defaultMarker` pendant ce chargement : une
  // alerte n'est jamais représentée par une épingle Google Maps générique.
  final Map<IncidentType, gmaps.BitmapDescriptor> _incidentMarkerIcons = {};
  final Set<IncidentType> _incidentMarkerIconsLoading = {};

  // Proximity alert toast
  bool _alertToastDismissed = false;

  // Degraded states
  double? _currentAccuracy;
  DateTime? _lastSyncTime;
  bool _locationPermissionDenied = false;
  bool _locationPermissionPermanentlyDenied = false;
  bool _isRetryingSync = false;
  bool _emptyCardDismissed = false;
  ({ContactRelation rel, RtdbContactSnapshot snap})? _selectedContactDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _connectivity = result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (mounted) setState(() => _connectivity = result);
    });
  }

  NavigationProvider? _navigationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _locationService = context.read<LocationService>();
      _alertProvider = context.read<AlertProvider>();
      _dependenciesInitialized = true;
    }
    if (!_alertListenerAttached) {
      _alertProvider.addListener(_onAlertCreated);
      _alertListenerAttached = true;
    }

    final nav = context.read<NavigationProvider>();
    if (_navigationProvider != nav) {
      _navigationProvider?.removeListener(_onNavigationChanged);
      _navigationProvider = nav;
      nav.addListener(_onNavigationChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeServices();
    });
    _subscribeToLocationUpdates();
  }

  void _onNavigationChanged() {
    final focus = _navigationProvider?.pendingFocus;
    if (focus == null) return;
    _navigationProvider?.clearFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(focus.lat, focus.lng),
          17.0,
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraDebounceTimer?.cancel();
    _locationSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _alertProvider.removeListener(_onAlertCreated);
    _navigationProvider?.removeListener(_onNavigationChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (_locationPermissionDenied) {
          _handlePermissionRetryAfterSettings();
        } else {
          _initializeServices();
          _subscribeToLocationUpdates();
        }
        break;
      case AppLifecycleState.paused:
        _locationSubscription?.cancel();
        _locationSubscription = null;
        break;
      default:
        break;
    }
  }

  double _severityHue(DangerSeverity? severity) => switch (severity) {
    DangerSeverity.high => gmaps.BitmapDescriptor.hueRed,
    DangerSeverity.med => gmaps.BitmapDescriptor.hueOrange,
    _ => gmaps.BitmapDescriptor.hueYellow,
  };

  // ─── Viewport ────────────────────────────────────────────────────────────────

  void _onCameraMove(gmaps.CameraPosition position) {
    _currentZoom = position.zoom;
    _lastCameraPosition = position;
    _cameraDebounceTimer?.cancel();
    _cameraDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _loadViewport(position);
    });
  }

  void _onAlertCreated() {
    final ap = context.read<AlertProvider>();
    if (ap.createdCount > _lastAlertCreatedCount) {
      _lastAlertCreatedCount = ap.createdCount;
      _viewportCache.invalidate();
      _lastViewportKey = null;
      final cam = _lastCameraPosition;
      if (cam != null) _loadViewport(cam);
    }
  }

  Future<void> _loadViewport(gmaps.CameraPosition position) async {
    if (!mounted || _controller == null) return;

    final bounds = await _controller!.getVisibleRegion();
    final zoom = position.zoom.round();

    final key = MapViewportCache.buildKey(
      south: bounds.southwest.latitude,
      north: bounds.northeast.latitude,
      west: bounds.southwest.longitude,
      east: bounds.northeast.longitude,
      zoom: zoom,
    );

    if (key == _lastViewportKey) return;

    // Les incidents communautaires ne dépendent pas du cache des zones de
    // danger. Les charger avant les retours anticipés évite qu'une alerte
    // active soit absente quand ce viewport de zones est déjà en mémoire.
    unawaited(context.read<IncidentProvider>().loadForBounds(bounds));

    // Ne pas marquer ce viewport comme traité tant que le chargement précédent
    // des zones n'est pas terminé : un mouvement rapide de caméra devra encore
    // pouvoir déclencher son chargement de zones.
    if (_viewportLoading) return;

    _lastViewportKey = key;

    if (_viewportCache.contains(key)) {
      _applyViewportZones(_viewportCache.get(key)!);
      return;
    }

    _viewportLoading = true;
    try {
      if (!mounted) return;
      final repo = context.read<DangerZoneRepository>();
      final zones = await repo.getViewportDangerZones(
        south: bounds.southwest.latitude,
        north: bounds.northeast.latitude,
        west: bounds.southwest.longitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
      );
      _viewportCache.set(key, zones);
      if (mounted) _applyViewportZones(zones);
    } catch (e) {
      log('MapTab._loadViewport error: $e');
    } finally {
      _viewportLoading = false;
    }

  }

  void _applyViewportZones(List<DangerZone> zones) {
    final markers = <gmaps.Marker>{};
    for (final zone in zones) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('danger_${zone.id}'),
          position: gmaps.LatLng(zone.center.lat, zone.center.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            _severityHue(zone.severity),
          ),
          infoWindow: gmaps.InfoWindow(
            title: zone.title,
            snippet: zone.description,
          ),
          onTap: () => setState(() {
            _selectedDanger = zone;
            _selectedSafe = null;
          }),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _dangerMarkers = markers;
        _dangerZones = zones;
      });
    }
  }

  // ─── Services & Location ─────────────────────────────────────────────────────

  Future<void> _initializeServices() async {
    try {
      log('[MapTab] _initializeServices start');
      if (mounted) await context.read<ZonesNotifier>().loadZones();
      final granted = await PermissionsService.isLocationPermissionGranted();
      final serviceEnabled =
          await ph.Permission.locationWhenInUse.serviceStatus.isEnabled;
      log(
        '[MapTab] location permission granted=$granted serviceEnabled=$serviceEnabled',
      );
      if (!granted || !serviceEnabled) {
        final permanentlyDenied =
            (await ph.Permission.locationWhenInUse.status).isPermanentlyDenied;
        if (mounted)
          await _showLocationPermissionDialog(
            permanentlyDenied: permanentlyDenied,
          );
        return;
      }
      if (!mounted) return;
      await _locationService.initialize();
      log('[MapTab] LocationService initialized');
      await _locationService.startTracking();
      log('[MapTab] tracking started');
    } catch (e) {
      log('[MapTab] _initializeServices error: $e');
    }
  }

  Future<void> _showLocationPermissionDialog({
    bool permanentlyDenied = false,
  }) async {
    if (mounted) {
      setState(() {
        _locationPermissionDenied = true;
        _locationPermissionPermanentlyDenied = permanentlyDenied;
      });
    }
  }

  Future<void> _handleOpenSettings() async {
    await ph.openAppSettings();
    // Re-check permission when user comes back from settings
    // didChangeAppLifecycleState handles this
  }

  Future<void> _handlePermissionRetryAfterSettings() async {
    final granted = await PermissionsService.isLocationPermissionGranted();
    final serviceEnabled =
        await ph.Permission.locationWhenInUse.serviceStatus.isEnabled;
    if (granted && serviceEnabled && mounted) {
      setState(() => _locationPermissionDenied = false);
      if (!mounted) return;
      await _locationService.initialize();
      await _locationService.startTracking();
      _locationSubscription?.cancel();
      _locationSubscription = null;
      setState(() => _loadingLocation = true);
      _subscribeToLocationUpdates();
    }
  }

  void _subscribeToLocationUpdates() {
    if (_locationSubscription != null) {
      log('[MapTab] _subscribeToLocationUpdates: already subscribed, skip');
      return;
    }
    log('[MapTab] subscribing to location stream, loadingLocation=true');
    setState(() => _loadingLocation = true);

    _locationSubscription = _locationService.locationStream.listen(
      (point) {
        if (!mounted) return;
        log(
          '[MapTab] location received lat=${point.latitude} lng=${point.longitude} acc=${point.accuracy} loadingLocation=$_loadingLocation',
        );
        final pos = gmaps.LatLng(point.latitude, point.longitude);
        setState(() {
          _currentPosition = pos;
          _currentAccuracy = point.accuracy;
          _lastSyncTime = DateTime.now();
          if (_loadingLocation) {
            log('[MapTab] animating camera to initial position');
            _loadingLocation = false;
            _controller?.animateCamera(gmaps.CameraUpdate.newLatLng(pos));
          }
        });
      },
      onError: (e) {
        log('[MapTab] location stream error: $e');
        if (mounted) setState(() => _loadingLocation = false);
      },
    );
  }

  void _moveCameraToFirstSafeZone(List<zone_models.Zone> safeZones) {
    if (_cameraMovedToZone || _currentPosition != null || _controller == null) {
      return;
    }
    if (safeZones.isEmpty) return;
    _cameraMovedToZone = true;
    final z = safeZones.first;
    _controller!.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(z.center.lat, z.center.lng),
        14.0,
      ),
    );
  }

  void _focusSafeZoneOnMap(zone_models.Zone zone) {
    setState(() {
      _selectedSafe = zone;
      _selectedDanger = null;
      _selectedContactDetail = null;
    });
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(zone.center.lat, zone.center.lng),
        _zoomForSafeZone(zone.radiusMeters),
      ),
    );
  }

  double _zoomForSafeZone(double radiusMeters) {
    if (radiusMeters <= 200) return 16;
    if (radiusMeters <= 500) return 15;
    if (radiusMeters <= 1500) return 14;
    return 13;
  }

  Future<void> _recenterCamera() async {
    log(
      '[MapTab] recenter tapped, currentPosition=$_currentPosition loadingLocation=$_loadingLocation isTracking=${_locationService.isTracking}',
    );
    if (_currentPosition != null) {
      log('[MapTab] animating camera to currentPosition');
      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
      );
      return;
    }
    final granted = await PermissionsService.isLocationPermissionGranted();
    log('[MapTab] recenter: permission granted=$granted');
    if (!mounted) return;
    if (!granted) {
      await _showLocationPermissionDialog();
    } else {
      log('[MapTab] recenter: one-shot getCurrentPosition');
      if (!_locationService.isTracking) {
        await _locationService.initialize();
        await _locationService.startTracking();
        _locationSubscription?.cancel();
        _locationSubscription = null;
        _subscribeToLocationUpdates();
      }
      if (!mounted) return;
      setState(() => _loadingLocation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation en cours d\'acquisition…'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      final point = await _locationService.getCurrentPosition();
      if (!mounted) return;
      if (point != null) {
        final pos = gmaps.LatLng(point.latitude, point.longitude);
        setState(() {
          _currentPosition = pos;
          _loadingLocation = false;
        });
        _controller?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(pos, 15.0));
        log('[MapTab] recenter: camera moved to $pos');
      } else {
        setState(() => _loadingLocation = false);
        log('[MapTab] recenter: getCurrentPosition returned null');
      }
    }
  }

  Future<void> _openInvisibleSheet() async {
    // CDC §10.1 — le mode invisible est réservé aux tiers payants.
    // On ne bloque que l'activation : si le mode est déjà actif, la feuille
    // doit rester accessible pour pouvoir reprendre le partage.
    if (!_invisibleActive) {
      final profile = await context.read<PrefsService>().getUserProfile();
      if (profile != null &&
          !profile.isPaidTier &&
          !SubscriptionService.instance.isPremium) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaywallPage(trigger: 'invisible_mode'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InvisibleModeSheet(
        isActive: _invisibleActive,
        invisibleUntil: _invisibleUntil,
        onActivate: (minutes) async {
          final prefs = context.read<PrefsService>();
          final svc = context.read<ApiLocationService>();
          try {
            final token = await prefs.getBearerToken();
            svc.setBearerToken(token);
            await svc.pauseLocation(durationMinutes: minutes);
            await _locationService.setInvisibleMode(true);
          } catch (e) {
            // Ne JAMAIS afficher « invisible » si le serveur a refusé : la
            // position continuerait d'être partagée alors que l'utilisateur
            // croit être masqué.
            log('invisible mode activate error: $e');
            return false;
          }
          if (mounted) {
            setState(() {
              _invisibleActive = true;
              _invisibleUntil = minutes != null
                  ? DateTime.now().add(Duration(minutes: minutes))
                  : null;
            });
          }
          return true;
        },
        onResume: () async {
          final prefs = context.read<PrefsService>();
          final svc = context.read<ApiLocationService>();
          try {
            final token = await prefs.getBearerToken();
            svc.setBearerToken(token);
            await svc.resumeLocation();
            await _locationService.setInvisibleMode(false);
          } catch (e) {
            log('invisible mode resume error: $e');
          }
          // On repasse toujours en visible côté UI : en cas d'échec réseau,
          // afficher « masqué » serait la promesse la plus dangereuse à tenir.
          _resumeInvisible();
          return true;
        },
      ),
    );
  }

  void _resumeInvisible() {
    setState(() {
      _invisibleActive = false;
      _invisibleUntil = null;
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer3<ZonesNotifier, RelationshipProvider, ContactRtdbService>(
      builder: (context, zonesNotifier, relProvider, rtdbService, _) {
        final safeZones = zonesNotifier.safeZones;
        _moveCameraToFirstSafeZone(safeZones);

        final safeCircles = _buildSafeCircles(safeZones);
        final contactMarkers = _buildContactMarkers(
          relProvider.realtimeContacts,
          rtdbService.snapshots,
        );
        final allMarkers = {
          ..._buildSafeMarkers(safeZones),
          ..._dangerMarkers,
          ...contactMarkers,
          ..._buildIncidentMarkers(),
        };

        final activeContacts = relProvider.acceptedRelationships.length;
        final hasContacts = activeContacts > 0;

        final routeProvider = context.watch<RouteProvider>();
        final activeRoute = routeProvider.isActive ? routeProvider.route : null;

        return Stack(
          children: [
            // ── Map ──────────────────────────────────────────────────────────
            gmaps.GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (ctrl) {
                _controller = ctrl;
                if (_currentPosition != null) {
                  ctrl.animateCamera(
                    gmaps.CameraUpdate.newLatLng(_currentPosition!),
                  );
                }
              },
              onCameraMove: _onCameraMove,
              onTap: (_) => setState(() {
                _selectedDanger = null;
                _selectedSafe = null;
                _selectedContactDetail = null;
              }),
              markers: allMarkers,
              circles: {
                ...safeCircles,
                if (_currentZoom >= 13) ..._buildDangerCircles(),
                ..._buildIncidentHalos(),
                if (_currentPosition != null &&
                    _currentAccuracy != null &&
                    _currentAccuracy! > 50)
                  gmaps.Circle(
                    circleId: const gmaps.CircleId('gps_accuracy'),
                    center: _currentPosition!,
                    radius: _currentAccuracy!,
                    fillColor: const Color(0x1A1E6868),
                    strokeColor: AppColors.primary,
                    strokeWidth: 1,
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: context.watch<MapTypeNotifier>().type,
              onLongPress: (_) => _openInvisibleSheet(),
            ),

            // ── Offline grey overlay ──────────────────────────────────────────
            if (_connectivity.every((r) => r == ConnectivityResult.none))
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.grey.withValues(alpha: 0.12)),
                ),
              ),

            // ── Offline banner (dark chip) ────────────────────────────────────
            if (_connectivity.every((r) => r == ConnectivityResult.none))
              Builder(
                builder: (context) {
                  final minutes = _lastSyncTime != null
                      ? DateTime.now().difference(_lastSyncTime!).inMinutes
                      : null;
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 0,
                    right: 0,
                    child: OfflineBanner(minutesSinceUpdate: minutes),
                  );
                },
              ),

            // ── Proximity alert toast ─────────────────────────────────────────
            Builder(
              builder: (_) {
                final alert = _nearestProximityAlert();
                if (alert == null) return const SizedBox.shrink();
                final color = alert.zone.severity == DangerSeverity.high
                    ? AppColors.danger
                    : AppColors.gravityMid;
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 64,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(color: color, width: 4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danger signalé à ${alert.distanceM}m',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  '${alert.zone.title} · ${alert.zone.confirmations} conf.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _alertToastDismissed = true),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Invisible mode banner ─────────────────────────────────────────
            if (_invisibleActive)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 0,
                right: 0,
                child: InvisibleModeBanner(
                  invisibleUntil: _invisibleUntil,
                  onResume: _resumeInvisible,
                ),
              ),

            // ── GPS imprecise banner ──────────────────────────────────────────
            if (_currentAccuracy != null &&
                _currentAccuracy! > 100 &&
                _connectivity.any((r) => r != ConnectivityResult.none))
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: GpsImpreciseBanner(accuracyMeters: _currentAccuracy!),
              ),

            // ── Low battery banner ────────────────────────────────────────────
            Builder(
              builder: (_) {
                final lowBatteryContact = _findLowBatteryContact(
                  relProvider.realtimeContacts,
                  rtdbService.snapshots,
                );
                if (lowBatteryContact == null) return const SizedBox.shrink();
                final bannerTop =
                    _currentAccuracy != null && _currentAccuracy! > 100
                    ? MediaQuery.of(context).padding.top + 104
                    : MediaQuery.of(context).padding.top + 60;
                return Positioned(
                  top: bannerTop,
                  left: 0,
                  right: 0,
                  child: LowBatteryBanner(
                    contactName: lowBatteryContact.rel.contact.name
                        .split(' ')
                        .first,
                    batteryPercent: lowBatteryContact.snap.batteryLevel!,
                    onTap: () => setState(
                      () => _selectedContactDetail = lowBatteryContact,
                    ),
                  ),
                );
              },
            ),

            // ── V4 Header overlay ─────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapHeader(
                connectivity: _connectivity,
                activeContacts: activeContacts,
                onLayersTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'zones',
                    barrierColor: Colors.black54,
                    transitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (_, __, ___) => ZonesPanel(
                      onViewOnMap: _focusSafeZoneOnMap,
                    ),
                    transitionBuilder: (_, anim, __, child) => SlideTransition(
                      position:
                          Tween(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
              ),
            ),

            // ── Barre de recherche d'itinéraire (V4.1 §6.1) ──────────────────
            // Sous le header, comme Google Maps / Apple Plans / Waze. Aucun
            // emplacement de navigation consommé : la tab bar reste à 3 entrées.
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 16,
              right: 16,
              child: RouteSearchBar(onTap: _openRouteSearch),
            ),

            // ── Bandeau trajet en cours (V4.1 §5.4/§5.5) ─────────────────────
            if (activeRoute != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 136,
                left: 0,
                right: 0,
                child: ActiveRouteBanner(
                  destinationLabel: activeRoute.destinationLabel,
                  onStop: _stopActiveRoute,
                ),
              ),

            // ── Recenter FAB ─────────────────────────────────────────────────
            Positioned(
              bottom: hasContacts ? 24 : 180,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'recenter',
                onPressed: _recenterCamera,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.my_location),
              ),
            ),

            // ── Type de carte ────────────────────────────────────────────────
            Positioned(
              bottom: (hasContacts ? 24 : 180) + 56,
              right: 16,
              child: const MapTypeToggleButton(),
            ),

            // ── Empty state card (no contacts) ───────────────────────────────
            if (!hasContacts && !_emptyCardDismissed)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _EmptyStateCard(
                  onInvite: () => _openInvitation(relProvider),
                  onDiscover: () => setState(() => _emptyCardDismissed = true),
                ),
              ),

            // ── Offline cache card ────────────────────────────────────────────
            if (_connectivity.every((r) => r == ConnectivityResult.none) &&
                hasContacts)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: OfflineCacheCard(
                  isRetrying: _isRetryingSync,
                  onRetry: () async {
                    setState(() => _isRetryingSync = true);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _isRetryingSync = false);
                  },
                ),
              ),

            // ── Bottom sheets ─────────────────────────────────────────────────
            if (_selectedContactDetail != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildContactDetailSheet(
                  _selectedContactDetail!.rel,
                  _selectedContactDetail!.snap,
                ),
              ),

            if (_selectedDanger != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDangerBottomSheet(_selectedDanger!),
              ),

            if (_selectedSafe != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildSafeZoneBottomSheet(_selectedSafe!),
              ),

            // ── Location permission overlay (full screen) ─────────────────────
            if (_locationPermissionDenied)
              Positioned.fill(
                child: LocationPermissionOverlay(
                  isPermanentlyDenied: _locationPermissionPermanentlyDenied,
                  onOpenSettings: _handleOpenSettings,
                  onContinueWithout: () =>
                      setState(() => _locationPermissionDenied = false),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openInvitation(RelationshipProvider relationshipProvider) async {
    final profile = await PrefsService().getUserProfile();

    if (profile?.isPaidTier != true &&
        PaywallTriggerService.checkContactLimit(
          relationshipProvider.acceptedRelationships.length,
        )) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallPage(trigger: 'contact_limit'),
        ),
      );
      return;
    }

    if (mounted) context.push(AppRoutes.addProche);
  }

  // ─── Markers & Circles ───────────────────────────────────────────────────────

  Set<gmaps.Marker> _buildSafeMarkers(List<zone_models.Zone> zones) => {
    for (final z in zones)
      gmaps.Marker(
        markerId: gmaps.MarkerId('safe_${z.id}'),
        position: gmaps.LatLng(z.center.lat, z.center.lng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen,
        ),
        infoWindow: gmaps.InfoWindow(
          title: z.name,
          snippet: z.description ?? 'Zone de sécurité',
        ),
        onTap: () => setState(() {
          _selectedSafe = z;
          _selectedDanger = null;
        }),
      ),
  };

  Set<gmaps.Circle> _buildSafeCircles(List<zone_models.Zone> zones) => {
    for (final z in zones)
      gmaps.Circle(
        circleId: gmaps.CircleId('safe_circle_${z.id}'),
        center: gmaps.LatLng(z.center.lat, z.center.lng),
        radius: z.radiusMeters,
        fillColor: AppColors.success.withValues(alpha: 0.12),
        strokeColor: AppColors.success,
        strokeWidth: 2,
      ),
  };

  Set<gmaps.Circle> _buildDangerCircles() => {
    for (final zone in _dangerZones)
      gmaps.Circle(
        circleId: gmaps.CircleId('danger_circle_${zone.id}'),
        center: gmaps.LatLng(zone.center.lat, zone.center.lng),
        radius: zone.radiusMeters,
        fillColor: _severityColor(zone.severity).withValues(alpha: 0.12),
        strokeColor: _severityColor(zone.severity),
        strokeWidth: 2,
      ),
  };

  /// Halos d'incidents communautaires — CDC V4.1 §4.4 / §11.1
  ///
  /// On dessine `display_radius_m`, jamais la géométrie d'évitement. Un
  /// signalement communautaire est imprécis (GPS urbain ±10 à 50 m) : le halo
  /// communique honnêtement « quelque part par ici », là où un corridor fin
  /// prétendrait une précision que la donnée ne possède pas.
  Set<gmaps.Circle> _buildIncidentHalos() {
    final incidents = context.watch<IncidentProvider>().incidents;

    return {
      for (final incident in incidents)
        gmaps.Circle(
          circleId: gmaps.CircleId('incident_${incident.id}'),
          center: incident.position,
          radius: incident.displayRadiusM.toDouble(),
          fillColor: incident.severity.color.withValues(alpha: 0.15),
          strokeColor: incident.severity.color,
          strokeWidth: _incidentHaloStrokeWidth(incident.confirmCount),
          consumeTapEvents: true,
          onTap: () => IncidentDetailSheet.show(context, incident),
        ),
    };
  }

  /// Marqueurs bitmap propres aux catégories d'incidents communautaires.
  ///
  /// Tant qu'un bitmap n'est pas prêt, le marqueur est simplement différé. Cela
  /// évite le bref affichage d'une épingle standard avant son remplacement.
  Set<gmaps.Marker> _buildIncidentMarkers() {
    final incidents = context.watch<IncidentProvider>().incidents;
    final types = incidents.map((incident) => incident.type).toSet();
    for (final type in types) {
      _ensureIncidentMarkerIcon(type);
    }

    return {
      for (final incident in incidents)
        if (_incidentMarkerIcons[incident.type] case final icon?)
          gmaps.Marker(
            markerId: gmaps.MarkerId('incident_marker_${incident.id}'),
            position: incident.position,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: gmaps.InfoWindow(
              title: incident.type.label,
              snippet: incident.reportCountLabel,
            ),
            onTap: () => IncidentDetailSheet.show(context, incident),
          ),
    };
  }

  /// Épaisseur en px du contour du halo, selon les confirmations sur place.
  /// Une croissance racine carrée conserve une différence lisible sur les
  /// petits nombres sans transformer les incidents très confirmés en disque.
  int _incidentHaloStrokeWidth(int confirmCount) {
    final confirmations = math.max(0, confirmCount);
    return (2 + math.sqrt(confirmations) * 2).round().clamp(2, 10).toInt();
  }

  void _ensureIncidentMarkerIcon(IncidentType type) {
    if (_incidentMarkerIcons.containsKey(type) ||
        !_incidentMarkerIconsLoading.add(type)) {
      return;
    }

    unawaited(
      _makeIncidentMarker(type).then((icon) {
        if (!mounted) return;
        setState(() => _incidentMarkerIcons[type] = icon);
      }).catchError((Object error, StackTrace stackTrace) {
        log('MapTab._makeIncidentMarker($type) error: $error',
            stackTrace: stackTrace);
      }).whenComplete(() => _incidentMarkerIconsLoading.remove(type)),
    );
  }

  IconData _incidentIcon(IncidentType type) => switch (type) {
    IncidentType.accident => Icons.car_crash,
    IncidentType.fire => Icons.local_fire_department,
    IncidentType.aggression => Icons.warning_amber_rounded,
    IncidentType.suspect => Icons.person_search,
    IncidentType.suspiciousPackage => Icons.inventory_2,
    IncidentType.roadworks => Icons.construction,
    IncidentType.trafficJam => Icons.traffic,
    IncidentType.flood => Icons.flood,
    IncidentType.protest => Icons.campaign,
    IncidentType.other => Icons.notifications_active,
  };

  Color _incidentMarkerColor(IncidentType type) => switch (type) {
    IncidentType.accident => const Color(0xFFB3261E),
    IncidentType.fire => const Color(0xFFE65100),
    IncidentType.aggression => const Color(0xFF9C1C31),
    IncidentType.suspect => const Color(0xFF6A1B9A),
    IncidentType.suspiciousPackage => const Color(0xFF795548),
    IncidentType.roadworks => const Color(0xFFF57C00),
    IncidentType.trafficJam => const Color(0xFFC62828),
    IncidentType.flood => const Color(0xFF0277BD),
    IncidentType.protest => const Color(0xFF1565C0),
    IncidentType.other => AppColors.primary,
  };

  Future<gmaps.BitmapDescriptor> _makeIncidentMarker(IncidentType type) async {
    const size = 56.0;
    const center = Offset(size / 2, size / 2);
    const radius = 22.0;
    final color = _incidentMarkerColor(type);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      radius,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final icon = _incidentIcon(type);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Ouvre le module Trajets — §6.1. Aucun onglet consommé : la barre
  /// d'onglets reste à trois entrées.
  Future<void> _openRouteSearch() async {
    final result = await Navigator.of(context).push<RouteSearchResult>(
      MaterialPageRoute(
        builder: (_) => RouteSearchPage(initialOrigin: _currentPosition),
      ),
    );

    if (result == null || !mounted) return;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RoutePreviewPage(search: result)));
  }

  /// Arrête un trajet actif (bandeau §5.4/§5.5) — désarme la surveillance
  /// serveur avant que la destination soit atteinte.
  Future<void> _stopActiveRoute() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arrêter le trajet ?'),
        content: const Text(
          'La surveillance de ce trajet sera désactivée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Arrêter',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final stopped = await context.read<RouteProvider>().cancelRoute();
    if (!mounted) return;

    if (!stopped) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'arrêter le trajet pour le moment.'),
        ),
      );
    }
  }

  Set<gmaps.Marker> _buildContactMarkers(
    List<ContactRelation> contacts,
    Map<String, RtdbContactSnapshot> snapshots,
  ) {
    final markers = <gmaps.Marker>{};
    final isOffline = _connectivity.every((r) => r == ConnectivityResult.none);

    for (final rel in contacts) {
      if (!rel.canSeeContact) continue;
      final uid = rel.contact.firebaseUid;
      if (uid == null) continue;
      final snap = snapshots[uid];
      if (snap == null || snap.isInvisible) continue;

      final isStale =
          DateTime.now().difference(snap.updatedAt) >
          const Duration(minutes: 15);
      // Online + stale → skip. Offline → always show from cache.
      if (isStale && !isOffline) continue;

      final battery = snap.batteryLevel;
      final isLowBattery = battery != null && battery < 20;
      final showAsStale = isStale || isOffline;
      final cacheKey = '${uid}_${battery ?? -1}_$showAsStale';

      final icon = _contactMarkerIcons[cacheKey];
      if (icon == null) {
        _makeContactMarker(
          rel.contact.name,
          batteryLevel: battery,
          stale: showAsStale,
        ).then((desc) {
          if (!mounted) return;
          setState(() => _contactMarkerIcons[cacheKey] = desc);
        });
      }

      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('contact_$uid'),
          position: gmaps.LatLng(snap.latitude, snap.longitude),
          icon:
              icon ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(
                isLowBattery
                    ? gmaps.BitmapDescriptor.hueRed
                    : showAsStale
                    ? gmaps.BitmapDescriptor.hueAzure
                    : gmaps.BitmapDescriptor.hueCyan,
              ),
          onTap: () =>
              setState(() => _selectedContactDetail = (rel: rel, snap: snap)),
        ),
      );
    }
    return markers;
  }

  Color _severityColor(DangerSeverity severity) => switch (severity) {
    DangerSeverity.high => AppColors.danger,
    DangerSeverity.med => AppColors.gravityMid,
    DangerSeverity.low => AppColors.gravityLow,
  };

  // ─── Bottom Sheets ───────────────────────────────────────────────────────────

  Widget _buildDangerBottomSheet(DangerZone zone) {
    return _BottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  zone.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _SeverityChip(zone.severity),
            ],
          ),
          if (zone.description != null && zone.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              zone.description!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${zone.confirmations} confirmation${zone.confirmations > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatTimeAgo(zone.lastReportAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedDanger = null),
                  child: const Text('Fermer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/zone-danger/detail/${zone.id}'),
                  child: const Text('Voir détails'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeZoneBottomSheet(zone_models.Zone zone) {
    return _BottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (zone.description != null && zone.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              zone.description!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Rayon : ${zone.radiusMeters.toInt()} m',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedSafe = null),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailSheet(
    ContactRelation rel,
    RtdbContactSnapshot snap,
  ) {
    final isLowBattery = (snap.batteryLevel ?? 100) < 20;
    final isImprecise = snap.accuracy > 100;
    final tt = Theme.of(context).textTheme;

    return _BottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLowBattery ? AppColors.danger : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  rel.contact.name.isNotEmpty
                      ? rel.contact.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rel.contact.name.split(' ').first,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isImprecise) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'localisation imprécise',
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '±${snap.accuracy.toInt()} m',
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAgo(snap.updatedAt),
                      style: tt.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (isLowBattery && snap.batteryLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.battery_alert_rounded,
                        color: AppColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${snap.batteryLevel}%',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isImprecise) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La précision revient automatiquement en extérieur.',
                      style: tt.bodySmall?.copyWith(
                        color: const Color(0xFF92600A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isLowBattery) ...[
            const SizedBox(height: 12),
            Text(
              'Avise-le ou propose un point de rendez-vous',
              style: tt.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Lui écrire'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('L\'appeler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isLowBattery && !isImprecise)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _selectedContactDetail = null),
                  child: const Text('Fermer'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inDays > 0) return 'Il y a ${d.inDays}j';
    if (d.inHours > 0) return 'Il y a ${d.inHours}h';
    if (d.inMinutes > 0) return 'Il y a ${d.inMinutes}min';
    return 'À l\'instant';
  }

  // ─── Custom contact marker bitmap ────────────────────────────────────────────

  Future<gmaps.BitmapDescriptor> _makeContactMarker(
    String name, {
    int? batteryLevel,
    bool stale = false,
  }) async {
    const circleR = 26.0;
    const circleD = circleR * 2;
    const labelH = 20.0;
    const gap = 4.0;
    const totalW = 90.0;
    const totalH = circleD + gap + labelH;

    final isLowBattery = batteryLevel != null && batteryLevel < 20;
    final circleColor = stale
        ? const Color(0xFFB0B0B0)
        : isLowBattery
        ? AppColors.danger
        : AppColors.primary;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalW, totalH));

    final cx = totalW / 2;
    const cy = circleR;

    // Shadow
    canvas.drawCircle(
      Offset(cx, cy + 2),
      circleR,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Circle fill
    canvas.drawCircle(Offset(cx, cy), circleR, Paint()..color = circleColor);

    // Border: dashed for stale, solid for normal
    if (stale) {
      const dashCount = 12;
      const dashAngle = 2 * math.pi / dashCount;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < dashCount; i += 2) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: circleR - 1),
          i * dashAngle - math.pi / 2,
          dashAngle * 0.65,
          false,
          borderPaint,
        );
      }
    } else {
      canvas.drawCircle(
        Offset(cx, cy),
        circleR - 1,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Initial letter
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: stale ? Colors.white70 : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // Battery badge (bottom-right of circle)
    if (isLowBattery) {
      const badgeR = 10.0;
      final bx = cx + circleR * 0.65;
      final by = cy + circleR * 0.65;
      canvas.drawCircle(
        Offset(bx, by),
        badgeR,
        Paint()..color = AppColors.danger,
      );
      canvas.drawCircle(
        Offset(bx, by),
        badgeR,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      final btp = TextPainter(
        text: const TextSpan(text: '🔋', style: TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      btp.paint(canvas, Offset(bx - btp.width / 2, by - btp.height / 2));
    }

    // Name label pill
    const labelY = circleD + gap;
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, labelY + labelH / 2),
        width: totalW - 8,
        height: labelH,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rr,
      Paint()..color = stale ? Colors.grey[300]! : Colors.white,
    );

    final firstName = name.split(' ').first;
    final baseLabel = firstName.length > 8
        ? '${firstName.substring(0, 6)}…'
        : firstName;
    final label = isLowBattery ? '$baseLabel · $batteryLevel%' : baseLabel;
    final ltp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isLowBattery ? AppColors.danger : const Color(0xFF1A1A1A),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: totalW - 8);
    ltp.paint(
      canvas,
      Offset(cx - ltp.width / 2, labelY + (labelH - ltp.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(totalW.toInt(), totalH.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ─── Haversine ───────────────────────────────────────────────────────────────

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final a =
        math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dl / 2) * math.sin(dl / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  ({ContactRelation rel, RtdbContactSnapshot snap})? _findLowBatteryContact(
    List<ContactRelation> contacts,
    Map<String, RtdbContactSnapshot> snapshots,
  ) {
    for (final rel in contacts) {
      final uid = rel.contact.firebaseUid;
      if (uid == null) continue;
      final snap = snapshots[uid];
      if (snap == null || snap.isInvisible) continue;
      final battery = snap.batteryLevel;
      if (battery != null && battery < 20) return (rel: rel, snap: snap);
    }
    return null;
  }

  // Nearest medium/high danger zone within its radius from current position
  ({DangerZone zone, int distanceM})? _nearestProximityAlert() {
    if (_currentPosition == null || _alertToastDismissed) return null;
    DangerZone? best;
    double bestDist = double.infinity;
    for (final z in _dangerZones) {
      if (z.severity == DangerSeverity.low) continue;
      final d = _haversine(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        z.center.lat,
        z.center.lng,
      );
      if (d <= z.radiusMeters && d < bestDist) {
        best = z;
        bestDist = d;
      }
    }
    if (best == null) return null;
    return (zone: best, distanceM: bestDist.round());
  }
}

// ─── V4 Map Header ────────────────────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  final List<ConnectivityResult> connectivity;
  final int activeContacts;
  final VoidCallback onLayersTap;

  const _MapHeader({
    required this.connectivity,
    required this.activeContacts,
    required this.onLayersTap,
  });

  Color get _dotColor {
    if (connectivity.contains(ConnectivityResult.none) &&
        connectivity.length == 1) {
      return AppColors.danger;
    }
    if (connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.ethernet)) {
      return AppColors.success;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    final initials = user != null && user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .map((p) => p[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Layers button ───────────────────────────────────────
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onLayersTap,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          Icons.layers_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // ── Center: status dot + count ──────────────────────────
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _dotColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _dotColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeContacts > 0
                              ? '$activeContacts connecté${activeContacts > 1 ? 's' : ''}'
                              : 'Aucun proche',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Avatar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: user?.photoUrl != null
                          ? CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(user!.photoUrl!),
                            )
                          : CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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
        ),
      ),
    );
  }
}

// ─── Empty State Card ─────────────────────────────────────────────────────────

class _EmptyStateCard extends StatelessWidget {
  final VoidCallback onInvite;
  final VoidCallback? onDiscover;

  const _EmptyStateCard({required this.onInvite, this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_outline,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tes proches apparaîtront ici',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'L\'app prend tout son sens quand un proche est connecté avec toi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Inviter un proche →'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onDiscover,
            child: Text(
              'Découvrir l\'app d\'abord',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final Widget child;
  const _BottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final DangerSeverity severity;
  const _SeverityChip(this.severity);

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = switch (severity) {
      DangerSeverity.low => (AppColors.gravityLow, 'FAIBLE'),
      DangerSeverity.med => (AppColors.gravityMid, 'MOYEN'),
      DangerSeverity.high => (AppColors.danger, 'ÉLEVÉ'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
