// lib/features/zones_securite/presentation/widgets/zone_place_radius_step.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/models/safe_zone.dart' as models;
import '../../../../core/services/native_location_service.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/location_search_field.dart';
import 'dart:async';

class ZonePlaceRadiusStep extends StatefulWidget {
  final models.LatLng center;
  final double radius;
  final String? address;
  final void Function(models.LatLng center, double radius, String? address) onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool isCreating;

  const ZonePlaceRadiusStep({
    super.key,
    required this.center,
    required this.radius,
    required this.address,
    required this.onChanged,
    required this.onNext,
    required this.onPrev,
    this.isCreating = false,
  });

  @override
  State<ZonePlaceRadiusStep> createState() => _ZonePlaceRadiusStepState();
}

class _ZonePlaceRadiusStepState extends State<ZonePlaceRadiusStep> {
  GoogleMapController? _mapController;
  late models.LatLng _center;
  late double _radius;
  String? _address;
  bool _isLoading = false;
  bool _hasInitializedLocation = false;

  @override
  void initState() {
    super.initState();
    _center = widget.center;
    _radius = widget.radius;
    _address = widget.address;
    
    // Si la position initiale est la position par défaut (Yaoundé), 
    // essayer d'obtenir la position actuelle
    if (_center.lat == 3.87000 && _center.lng == 11.51500) {
      _getCurrentLocation();
    } else {
      _hasInitializedLocation = true;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      // Vérifier les permissions
      final permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        final requestResult = await Permission.locationWhenInUse.request();
        if (requestResult.isDenied) {
          if (!mounted) return;
          setState(() => _hasInitializedLocation = true);
          return;
        }
      }

      if (permission.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _hasInitializedLocation = true);
        return;
      }

      // Obtenir la position actuelle via notre service natif
      final nativeLocationService = NativeLocationService();
      
      // Écouter le stream de localisation pour obtenir la position actuelle
      StreamSubscription? locationSubscription;
      locationSubscription = nativeLocationService.locationStream.listen((locationPoint) {
        if (!mounted) return;
        setState(() {
          _center = models.LatLng(locationPoint.latitude, locationPoint.longitude);
          _hasInitializedLocation = true;
        });
        
        // Annuler l'écoute après avoir reçu la première position
        locationSubscription?.cancel();
      });
      
      // Si aucune position n'est reçue dans les 10 secondes, arrêter le chargement
      Timer(const Duration(seconds: 10), () {
        if (!_hasInitializedLocation) {
          locationSubscription?.cancel();
          if (mounted) {
            setState(() => _hasInitializedLocation = true);
          }
        }
      });

      _updateMapCamera();
      _notifyChange();
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la localisation: $e');
      if (!mounted) return;
      setState(() => _hasInitializedLocation = true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _updateMapCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_center.lat, _center.lng),
        16.0,
      ),
    );
  }

  void _notifyChange() {
    widget.onChanged(_center, _radius, _address);
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _center = models.LatLng(position.latitude, position.longitude);
    });
    _notifyChange();
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _radius = value;
    });
    _notifyChange();
  }

  void _onLocationSelected(LatLng position, String address) {
    setState(() {
      _center = models.LatLng(position.latitude, position.longitude);
      _address = address;
    });
    _updateMapCamera();
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et description
          Text(
            'Définir la localisation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Touchez la carte pour définir le centre de votre zone de sécurité',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 16),

          // Widget de recherche géographique
          LocationSearchField(
            onLocationSelected: _onLocationSelected,
          ),
          const SizedBox(height: 16),

          // Carte Google Maps
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Si la position a été initialisée, centrer la carte
                    if (_hasInitializedLocation) {
                      _updateMapCamera();
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_center.lat, _center.lng),
                    zoom: 16.0,
                  ),
                  onTap: _onMapTap,
                  circles: {
                    Circle(
                      circleId: const CircleId('safe_zone'),
                      center: LatLng(_center.lat, _center.lng),
                      radius: _radius,
                      fillColor: AppColors.safe.withOpacity(0.2),
                      strokeColor: AppColors.safe,
                      strokeWidth: 2,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('center'),
                      position: LatLng(_center.lat, _center.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contrôle du rayon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rayon de sécurité',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_radius.round()} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.teal,
                    inactiveTrackColor: AppColors.gray100,
                    thumbColor: AppColors.teal,
                    overlayColor: AppColors.teal.withOpacity(0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: _radius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    onChanged: _onRadiusChanged,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    Text(
                      '1000m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Boutons de navigation
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onPrev,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.gray100),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isCreating ? null : widget.onNext,
                  icon: widget.isCreating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                  label: Text(widget.isCreating ? 'Création...' : 'Créer la zone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
