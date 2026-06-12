import 'dart:async';
import 'package:alertcontacts/core/widgets/app_fab.dart';
import 'package:alertcontacts/core/widgets/location_search_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../../core/models/danger_zone.dart';
import '../../../core/models/zone.dart' as zone_models;
import '../../../core/repositories/dangerzone_repository.dart';
import '../../../core/services/native_location_service.dart';
import '../../../core/services/permissions_service.dart';
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
  late final NativeLocationService _nativeLocationService;
  StreamSubscription? _locationSubscription;
  gmaps.MapType _currentMapType = gmaps.MapType.hybrid;

  // Filtres
  bool _showDangers = true;
  bool _showSafeZones = true;

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

  // Caméra : évite de repositionner si l'utilisateur a déjà bougé
  bool _cameraMovedToZone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nativeLocationService = context.read<NativeLocationService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeServices();
    });
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraDebounceTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _initializeServices();
        _subscribeToLocationUpdates();
        break;
      case AppLifecycleState.paused:
        _locationSubscription?.cancel();
        _locationSubscription = null;
        break;
      default:
        break;
    }
  }

  double _severityHue(DangerSeverity? severity) {
    switch (severity) {
      case DangerSeverity.high:
        return gmaps.BitmapDescriptor.hueRed;
      case DangerSeverity.med:
        return gmaps.BitmapDescriptor.hueOrange;
      case DangerSeverity.low:
      default:
        return gmaps.BitmapDescriptor.hueYellow;
    }
  }

  // ─── Viewport Loading ────────────────────────────────────────────────────────

  void _onCameraMove(gmaps.CameraPosition position) {
    _currentZoom = position.zoom;
    _cameraDebounceTimer?.cancel();
    _cameraDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _loadViewport(position);
    });
  }

  Future<void> _loadViewport(gmaps.CameraPosition position) async {
    if (!mounted || _controller == null || _viewportLoading) return;

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
      debugPrint('MapTab._loadViewport error: $e');
    } finally {
      _viewportLoading = false;
    }
  }

  void _applyViewportZones(List<DangerZone> zones) {
    final markers = <gmaps.Marker>{};
    for (final zone in zones) {
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId('danger_${zone.id}'),
        position: gmaps.LatLng(zone.center.lat, zone.center.lng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(_severityHue(zone.severity)),
        infoWindow: gmaps.InfoWindow(
          title: zone.title,
          snippet: zone.description,
        ),
        onTap: () => setState(() {
          _selectedDanger = zone;
          _selectedSafe = null;
        }),
      ));
    }
    if (mounted) {
      setState(() {
        _dangerMarkers = markers;
        _dangerZones = zones;
      });
    }
  }

  // ─── Services & Localisation ─────────────────────────────────────────────────

  Future<void> _initializeServices() async {
    try {
      // Zones de sécurité : indépendantes des permissions de localisation
      if (mounted) {
        await context.read<ZonesNotifier>().loadZones();
      }

      final permissionsGranted =
          await PermissionsService.isPermissionsSetupComplete();
      if (!permissionsGranted) return;

      await _nativeLocationService.initialize();
      await _nativeLocationService.startTracking();
    } catch (e) {
      debugPrint('MapTab._initializeServices error: $e');
    }
  }

  void _subscribeToLocationUpdates() {
    if (_locationSubscription != null) return;
    setState(() => _loadingLocation = true);

    _locationSubscription = _nativeLocationService.locationStream.listen(
      (point) {
        if (!mounted) return;
        final pos = gmaps.LatLng(point.latitude, point.longitude);
        setState(() {
          _currentPosition = pos;
          if (_loadingLocation) {
            _loadingLocation = false;
            _controller?.animateCamera(gmaps.CameraUpdate.newLatLng(pos));
          }
        });
      },
      onError: (_) {
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

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ZonesNotifier>(
      builder: (context, zonesNotifier, _) {
        final safeZones = _showSafeZones ? zonesNotifier.safeZones : <zone_models.Zone>[];

        // Repositionner la caméra vers la première zone si pas de GPS
        _moveCameraToFirstSafeZone(safeZones);

        final safeMarkers = _buildSafeMarkers(safeZones);
        final safeCircles = _buildSafeCircles(safeZones);

        final allMarkers = {
          ...safeMarkers,
          if (_showDangers) ..._dangerMarkers,
        };

        return Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (ctrl) {
                _controller = ctrl;
                if (_currentPosition != null) {
                  ctrl.animateCamera(
                      gmaps.CameraUpdate.newLatLng(_currentPosition!));
                }
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: null,
              onTap: (_) => setState(() {
                _selectedDanger = null;
                _selectedSafe = null;
              }),
              markers: allMarkers,
              circles: {
                ...safeCircles,
                if (_showDangers && _currentZoom >= 13)
                  ..._buildDangerCircles(),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: _currentMapType,
            ),

            // Sélecteur de type de carte
            Positioned(
              top: 8,
              right: 54,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'map_type_selector',
                onPressed: () {},
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: PopupMenuButton<gmaps.MapType>(
                  onSelected: (t) => setState(() => _currentMapType = t),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: gmaps.MapType.normal, child: Text('Normal')),
                    PopupMenuItem(value: gmaps.MapType.satellite, child: Text('Satellite')),
                    PopupMenuItem(value: gmaps.MapType.hybrid, child: Text('Hybride')),
                    PopupMenuItem(value: gmaps.MapType.terrain, child: Text('Terrain')),
                  ],
                  icon: Icon(Icons.layers,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),

            // Barre de recherche
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: LocationSearchField(
                hintText: 'Rechercher un lieu sur la carte...',
                onLocationSelected: _onLocationSelected,
                margin: EdgeInsets.zero,
              ),
            ),

            // Filtres
            Positioned(
              top: 55,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Dangers'),
                        selected: _showDangers,
                        onSelected: (v) {
                          setState(() => _showDangers = v);
                          if (v) _lastViewportKey = null; // force rechargement
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sécurité'),
                        selected: _showSafeZones,
                        onSelected: (v) => setState(() => _showSafeZones = v),
                      ),
                      if (_viewportLoading) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Boutons d'action
            Positioned(
              bottom: 16,
              right: 16,
              child: LabeledFloatingActionButtonColumn(
                buttons: [
                  LabeledFloatingActionButton(
                    heroTag: 'danger',
                    onPressed: () => context.go('/zone-danger/create'),
                    backgroundColor: Colors.red,
                    icon: Icons.warning,
                    label: 'Signaler un danger',
                    tooltip: 'Créer une nouvelle zone de danger',
                    autoHideOnSmallScreen: false,
                  ),
                  LabeledFloatingActionButton(
                    heroTag: 'safe',
                    onPressed: () => context.go('/safezone/setup'),
                    backgroundColor: Colors.green,
                    icon: Icons.shield,
                    label: 'Créer une zone sûre',
                    tooltip: 'Créer une nouvelle zone de sécurité',
                    autoHideOnSmallScreen: false,
                  ),
                ],
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
          ],
        );
      },
    );
  }

  void _onLocationSelected(gmaps.LatLng position, String address) {
    _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(position, 16.0));
  }

  // ─── Markers & Circles ───────────────────────────────────────────────────────

  Set<gmaps.Marker> _buildSafeMarkers(List<zone_models.Zone> zones) {
    return {
      for (final z in zones)
        gmaps.Marker(
          markerId: gmaps.MarkerId('safe_${z.id}'),
          position: gmaps.LatLng(z.center.lat, z.center.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueGreen),
          infoWindow: gmaps.InfoWindow(
              title: z.name, snippet: z.description ?? 'Zone de sécurité'),
          onTap: () => setState(() {
            _selectedSafe = z;
            _selectedDanger = null;
          }),
        ),
    };
  }

  Set<gmaps.Circle> _buildSafeCircles(List<zone_models.Zone> zones) {
    return {
      for (final z in zones)
        gmaps.Circle(
          circleId: gmaps.CircleId('safe_circle_${z.id}'),
          center: gmaps.LatLng(z.center.lat, z.center.lng),
          radius: z.radiusMeters,
          fillColor: Colors.green.withValues(alpha: 0.15),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
    };
  }

  /// Cercles des danger zones visibles (uniquement zoom ≥ 13).
  Set<gmaps.Circle> _buildDangerCircles() {
    return {
      for (final zone in _dangerZones)
        gmaps.Circle(
          circleId: gmaps.CircleId('danger_circle_${zone.id}'),
          center: gmaps.LatLng(zone.center.lat, zone.center.lng),
          radius: zone.radiusMeters,
          fillColor: _severityColor(zone.severity).withValues(alpha: 0.15),
          strokeColor: _severityColor(zone.severity),
          strokeWidth: 2,
        ),
    };
  }

  Color _severityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.high:
        return Colors.red;
      case DangerSeverity.med:
        return Colors.orange;
      case DangerSeverity.low:
        return Colors.yellow.shade700;
    }
  }

  // ─── Bottom Sheets ───────────────────────────────────────────────────────────

  Widget _buildDangerBottomSheet(DangerZone zone) {
    return _BottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(zone.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            _SeverityChip(zone.severity),
          ]),
          if (zone.description != null && zone.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(zone.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.verified, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${zone.confirmations} confirmation${zone.confirmations > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(_formatTimeAgo(zone.lastReportAt),
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => setState(() => _selectedDanger = null),
                  child: const Text('Fermer')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                  onPressed: () => context.go('/zone-danger/detail/${zone.id}'),
                  child: const Text('Voir détails')),
            ),
          ]),
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
          Row(children: [
            const Icon(Icons.shield, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(zone.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ]),
          if (zone.description != null && zone.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(zone.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.radio_button_checked, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('Rayon : ${zone.radiusMeters.toInt()} m',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
                onPressed: () => setState(() => _selectedSafe = null),
                child: const Text('Fermer')),
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
}

// ─── Widgets locaux ──────────────────────────────────────────────────────────

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
              offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
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
      DangerSeverity.low  => (Colors.orange, 'FAIBLE'),
      DangerSeverity.med  => (Colors.deepOrange, 'MOYEN'),
      DangerSeverity.high => (Colors.red, 'ÉLEVÉ'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }
}
