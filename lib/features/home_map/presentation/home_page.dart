import 'package:alertcontacts/core/widgets/location_search_field.dart';
import 'package:alertcontacts/core/widgets/app_fab.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/danger_zone.dart';
import '../../../core/models/zone.dart' as zone_models;
import '../../../core/services/native_location_service.dart';
import '../../zones_danger/providers/danger_zone_notifier.dart';
import '../../zones/providers/zones_notifier.dart';
import 'dart:async';
import '../../../core/services/permissions_service.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with WidgetsBindingObserver {
  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(48.8566, 2.3522), // Paris par défaut
    zoom: 14.0,
  );

  gmaps.GoogleMapController? _controller;
  gmaps.LatLng? _currentPosition;
  bool _loadingLocation = false;
  Timer? _cameraDebounceTimer;
  late final NativeLocationService _nativeLocationService;
  StreamSubscription? _locationSubscription;
  gmaps.MapType _currentMapType = gmaps.MapType.hybrid;

  // Filtres
  bool _showDangers = true;
  bool _showSafeZones = true;
  final DangerSeverity _minSeverity = DangerSeverity.low;

  // Sélections
  DangerZone? _selectedDanger;
  zone_models.Zone? _selectedSafe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nativeLocationService = context.read<NativeLocationService>();
    _initializeServices();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraDebounceTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  /// Gère les changements d'état du cycle de vie de l'application
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('App au premier plan - redémarrage du suivi');
        _initializeServices();
        _subscribeToLocationUpdates();
        break;

      case AppLifecycleState.paused:
        print('App en arrière-plan - économie des ressources');
        _locationSubscription?.cancel();
        _locationSubscription = null; // Important pour la reprise
        break;

      case AppLifecycleState.detached:
        print('App fermée - vérification persistance service background');
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        print('App inactive/cachée - maintien services essentiels');
        break;
    }
  }

  /// Initialise les services de surveillance automatique
  Future<void> _initializeServices() async {
    try {
      // Vérifier si les permissions sont accordées
      final permissionsGranted =
          await PermissionsService.isPermissionsSetupComplete();
      if (!permissionsGranted) {
        print(
          'Permissions non accordées. Le service de localisation ne sera pas démarré.',
        );
        return;
      }

      // Démarrer le service de géolocalisation natif
      await _nativeLocationService.initialize();

      // Démarrer le suivi
      await _nativeLocationService.startTracking();

      // Charger les zones de sécurité de l'utilisateur
      if (mounted) {
        final zonesNotifier = Provider.of<ZonesNotifier>(
          context,
          listen: false,
        );
        await zonesNotifier.loadZones();
      }

      print(
        'Services de surveillance initialisés avec succès (premier plan + arrière-plan)',
      );
    } catch (e) {
      print('Erreur lors de l\'initialisation des services: $e');
    }
  }

  /// Charge les zones de danger pour une région donnée
  Future<void> _loadDangerZonesForRegion(
    gmaps.LatLng center,
    double radiusKm,
  ) async {
    if (!mounted) return;

    try {
      final dangerZoneNotifier = Provider.of<DangerZoneNotifier>(
        context,
        listen: false,
      );
      await dangerZoneNotifier.loadDangerZones(
        lat: center.latitude,
        lng: center.longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      debugPrint('Erreur lors du chargement des zones de danger: $e');
    }
  }

  /// Gère le mouvement de la caméra avec debounce pour éviter trop d'appels API
  void _onCameraMove(gmaps.CameraPosition position) {
    _cameraDebounceTimer?.cancel();
    _cameraDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Calculer le rayon visible basé sur le zoom
      final zoom = position.zoom;
      final radiusKm = _calculateVisibleRadius(zoom);

      // Charger les zones de danger pour la région visible
      _loadDangerZonesForRegion(position.target, radiusKm);
    });
  }

  /// Calcule le rayon visible en fonction du niveau de zoom
  double _calculateVisibleRadius(double zoom) {
    // Formule approximative pour calculer le rayon visible
    // Plus le zoom est élevé, plus le rayon est petit
    if (zoom >= 16) return 1.0; // 1 km
    if (zoom >= 14) return 2.0; // 2 km
    if (zoom >= 12) return 5.0; // 5 km
    if (zoom >= 10) return 10.0; // 10 km
    return 20.0; // 20 km pour les zooms plus larges
  }

  /// Gère la création d'une zone de sécurité (accès libre)
  Future<void> _onCreateSafeZone() async {
    // Accès libre à la création de zones de sécurité
    context.go('/safezone/setup');
  }

  void _subscribeToLocationUpdates() {
    if (_locationSubscription != null) return; // Déjà abonné

    setState(() => _loadingLocation = true);

    _locationSubscription = _nativeLocationService.locationStream.listen(
      (locationPoint) {
        if (!mounted) return;
        setState(() {
          _currentPosition = gmaps.LatLng(
            locationPoint.latitude,
            locationPoint.longitude,
          );
          if (_loadingLocation) {
            _loadingLocation = false;
            // Animer la caméra seulement la première fois
            _controller?.animateCamera(
              gmaps.CameraUpdate.newLatLng(_currentPosition!),
            );
          }
        });
      },
      onError: (error) {
        print("Erreur de stream de localisation: $error");
        if (mounted) {
          setState(() => _loadingLocation = false);
        }
      },
    );
  }

  /// Gère la création d'une zone de danger (accès premium)
  Future<void> _onCreateDangerZone() async {
    // Accès libre à la création de zones de sécurité
    context.go('/safezone/setup');
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);
    try {
      final nativeLocationService = NativeLocationService();

      // Écouter le stream de localisation pour obtenir la position actuelle
      StreamSubscription? locationSubscription;
      locationSubscription = nativeLocationService.locationStream.listen((
        locationPoint,
      ) {
        if (!mounted) return;
        setState(() {
          _currentPosition = gmaps.LatLng(
            locationPoint.latitude,
            locationPoint.longitude,
          );
        });

        // Animer la caméra vers la position actuelle
        if (_controller != null) {
          _controller!.animateCamera(
            gmaps.CameraUpdate.newLatLng(_currentPosition!),
          );
        }

        // Annuler l'écoute après avoir reçu la première position
        locationSubscription?.cancel();
        setState(() => _loadingLocation = false);
      });

      // Si aucune position n'est reçue dans les 10 secondes, arrêter le chargement
      Timer(const Duration(seconds: 10), () {
        if (_loadingLocation) {
          locationSubscription?.cancel();
          setState(() => _loadingLocation = false);
        }
      });

      // Charger les zones de danger pour la position actuelle
      await _loadDangerZonesForRegion(_currentPosition!, 2.0);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DangerZoneNotifier, ZonesNotifier>(
      builder: (context, dangerZoneNotifier, zonesNotifier, child) {
        // Filtrer les zones de danger
        final filteredDangers = _showDangers
            ? dangerZoneNotifier.state.zones.where((zone) {
                // Filtrer par fraîcheur (30 jours)
                final isRecent =
                    DateTime.now().difference(zone.lastReportAt).inDays <= 30;
                // Filtrer par sévérité minimale
                final severityOk = zone.severity.index >= _minSeverity.index;
                return isRecent && severityOk;
              }).toList()
            : <DangerZone>[];

        // Filtrer les zones de sécurité
        final filteredSafeZones = _showSafeZones
            ? zonesNotifier.safeZones
            : <zone_models.Zone>[];

        return Stack(
          children: [
            // Carte Google Maps
            gmaps.GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (gmaps.GoogleMapController controller) {
                _controller = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(
                    gmaps.CameraUpdate.newLatLng(_currentPosition!),
                  );
                }
              },
              onCameraMove: _onCameraMove,
              onTap: (gmaps.LatLng position) {
                // Fermer les bottom sheets quand on clique sur la carte
                setState(() {
                  _selectedDanger = null;
                  _selectedSafe = null;
                });
              },
              markers: _buildMarkers(filteredDangers, filteredSafeZones),
              circles: _buildCircles(filteredDangers, filteredSafeZones),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: _currentMapType,
            ),

            // Bouton pour changer le type de carte
            Positioned(
              top: 8,
              right: 54,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'map_type_selector',
                onPressed: () {},
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: PopupMenuButton<gmaps.MapType>(
                  onSelected: (gmaps.MapType result) {
                    setState(() {
                      _currentMapType = result;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<gmaps.MapType>>[
                        const PopupMenuItem<gmaps.MapType>(
                          value: gmaps.MapType.normal,
                          child: Text('Normal'),
                        ),
                        const PopupMenuItem<gmaps.MapType>(
                          value: gmaps.MapType.satellite,
                          child: Text('Satellite'),
                        ),
                        const PopupMenuItem<gmaps.MapType>(
                          value: gmaps.MapType.hybrid,
                          child: Text('Hybride'),
                        ),
                        const PopupMenuItem<gmaps.MapType>(
                          value: gmaps.MapType.terrain,
                          child: Text('Terrain'),
                        ),
                      ],
                  icon: Icon(
                    Icons.layers,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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

            // Boutons d'action flottants avec libellés
            Positioned(
              bottom: 16,
              right: 16,
              child: LabeledFloatingActionButtonColumn(
                buttons: [
                  LabeledFloatingActionButton(
                    heroTag: "danger",
                    onPressed: () => context.go('/zone-danger/create'),
                    backgroundColor: Colors.red,
                    icon: Icons.warning,
                    label: "Signaler un danger",
                    tooltip: "Créer une nouvelle zone de danger",
                    autoHideOnSmallScreen:
                        false, // Toujours afficher le libellé
                  ),
                  LabeledFloatingActionButton(
                    heroTag: "safe",
                    onPressed: _onCreateSafeZone,
                    backgroundColor: Colors.green,
                    icon: Icons.shield,
                    label: "Créer une zone sûre",
                    tooltip: "Créer une nouvelle zone de sécurité",
                    autoHideOnSmallScreen:
                        false, // Toujours afficher le libellé
                  ),
                ],
              ),
            ),

            // Filtres en bas de la barre de recherche
            Positioned(
              top: 55, // Ajusté pour ne pas superposer le nouveau bouton
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
                        onSelected: (selected) {
                          setState(() => _showDangers = selected);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sécurité'),
                        selected: _showSafeZones,
                        onSelected: (selected) {
                          setState(() => _showSafeZones = selected);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom sheet pour zone de danger sélectionnée
            if (_selectedDanger != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDangerBottomSheet(_selectedDanger!),
              ),

            // Bottom sheet pour zone de sécurité sélectionnée
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
    // Animer la caméra vers la position sélectionnée
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(position, 16.0),
    );
  }

  Set<gmaps.Marker> _buildMarkers(
    List<DangerZone> dangers,
    List<zone_models.Zone> safeZones,
  ) {
    final markers = <gmaps.Marker>{};

    // Marqueurs pour les zones de danger
    for (final danger in dangers) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('danger_${danger.id}'),
          position: gmaps.LatLng(danger.center.lat, danger.center.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
          infoWindow: gmaps.InfoWindow(
            title: danger.title,
            snippet: danger.description,
          ),
          onTap: () {
            setState(() {
              _selectedDanger = danger;
              _selectedSafe = null; // Fermer l'autre bottom sheet
            });
          },
        ),
      );
    }

    // Marqueurs pour les zones de sécurité
    for (final safe in safeZones.where((z) => z.isSafe == true)) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('safe_${safe.id}'),
          position: gmaps.LatLng(safe.center.lat, safe.center.lng),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: gmaps.InfoWindow(
            title: safe.name,
            snippet: safe.description ?? 'Zone de sécurité',
          ),
          onTap: () {
            setState(() {
              _selectedSafe = safe;
              _selectedDanger = null; // Fermer l'autre bottom sheet
            });
          },
        ),
      );
    }

    return markers;
  }

  Set<gmaps.Circle> _buildCircles(
    List<DangerZone> dangers,
    List<zone_models.Zone> safeZones,
  ) {
    final circles = <gmaps.Circle>{};

    // Cercles pour les zones de danger
    for (final danger in dangers) {
      circles.add(
        gmaps.Circle(
          circleId: gmaps.CircleId('danger_circle_${danger.id}'),
          center: gmaps.LatLng(danger.center.lat, danger.center.lng),
          radius: danger.radiusMeters,
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    }

    // Cercles pour les zones de sécurité
    for (final safe in safeZones.where((z) => z.isSafe == true)) {
      circles.add(
        gmaps.Circle(
          circleId: gmaps.CircleId('safe_circle_${safe.id}'),
          center: gmaps.LatLng(safe.center.lat, safe.center.lng),
          radius: safe.radiusMeters,
          fillColor: Colors.green.withOpacity(0.2),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  /// Bottom sheet pour les zones de danger
  Widget _buildDangerBottomSheet(DangerZone zone) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle pour glisser
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et gravité
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        zone.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSeverityChip(zone.severity),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                if (zone.description != null && zone.description!.isNotEmpty)
                  Text(
                    zone.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Informations rapides
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

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _selectedDanger = null);
                        },
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/zone-danger/detail/${zone.id}');
                        },
                        child: const Text('Voir détails'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet pour les zones de sécurité
  Widget _buildSafeZoneBottomSheet(zone_models.Zone zone) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle pour glisser
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et icône
                Row(
                  children: [
                    Icon(Icons.shield, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        zone.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                if (zone.description != null && zone.description!.isNotEmpty)
                  Text(
                    zone.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Informations
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rayon: ${zone.radiusMeters.toInt()}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Zone de sécurité',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bouton fermer
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedSafe = null);
                    },
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip pour afficher la gravité d'une zone de danger
  Widget _buildSeverityChip(DangerSeverity severity) {
    Color color;
    String text;

    switch (severity) {
      case DangerSeverity.low:
        color = Colors.orange;
        text = 'FAIBLE';
        break;
      case DangerSeverity.med:
        color = Colors.deepOrange;
        text = 'MOYEN';
        break;
      case DangerSeverity.high:
        color = Colors.red;
        text = 'ÉLEVÉ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  /// Formater le temps écoulé
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}
