import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../../core/models/safe_zone.dart'; // Pour LatLng
import '../../../../theme/colors.dart';
import '../../../../core/widgets/location_search_field.dart';

class DangerZoneLocationStep extends StatefulWidget {
  final LatLng center;
  final double radius;
  final ValueChanged<LatLng> onCenterChanged;
  final ValueChanged<double> onRadiusChanged;

  const DangerZoneLocationStep({
    super.key,
    required this.center,
    required this.radius,
    required this.onCenterChanged,
    required this.onRadiusChanged,
  });

  @override
  State<DangerZoneLocationStep> createState() => _DangerZoneLocationStepState();
}

class _DangerZoneLocationStepState extends State<DangerZoneLocationStep> {
  gmaps.GoogleMapController? _mapController;
  late gmaps.LatLng _currentCenter;
  late double _currentRadius;

  @override
  void initState() {
    super.initState();
    _currentCenter = gmaps.LatLng(widget.center.lat, widget.center.lng);
    _currentRadius = widget.radius;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Localisation du danger',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Placez le marqueur à l\'endroit du danger et ajustez la zone',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Widget de recherche géographique
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LocationSearchField(
            onLocationSelected: _onLocationSelected,
          ),
        ),
        const SizedBox(height: 16),

        // Carte
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.onSurface.withOpacity(0.1),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: gmaps.GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: gmaps.CameraPosition(
                target: _currentCenter,
                zoom: 16,
              ),
              onTap: _onMapTap,
              circles: {
                gmaps.Circle(
                  circleId: const gmaps.CircleId('danger_zone'),
                  center: _currentCenter,
                  radius: _currentRadius,
                  fillColor: AppColors.alert.withOpacity(0.2),
                  strokeColor: AppColors.alert,
                  strokeWidth: 2,
                ),
              },
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('danger_center'),
                  position: _currentCenter,
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueRed,
                  ),
                  draggable: true,
                  onDragEnd: _onMarkerDragEnd,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),

        // Contrôle du rayon
        _buildRadiusControl(context),
      ],
    );
  }

  Widget _buildRadiusControl(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rayon de la zone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.alert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentRadius.round()} m',
                  style: TextStyle(
                    color: AppColors.alert,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.alert,
              inactiveTrackColor: AppColors.alert.withOpacity(0.3),
              thumbColor: AppColors.alert,
              overlayColor: AppColors.alert.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _currentRadius,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (value) {
                setState(() => _currentRadius = value);
                widget.onRadiusChanged(value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10 m',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '500 m',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Boutons de rayon prédéfinis
          Row(
            children: [25, 50, 100, 200].map((radius) {
              final isSelected = _currentRadius == radius.toDouble();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: radius != 200 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentRadius = radius.toDouble());
                      widget.onRadiusChanged(radius.toDouble());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.alert : cs.surface,
                        border: Border.all(
                          color: isSelected ? AppColors.alert : cs.onSurface.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${radius}m',
                        style: TextStyle(
                          color: isSelected ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onMapTap(gmaps.LatLng position) {
    setState(() => _currentCenter = position);
    widget.onCenterChanged(LatLng(position.latitude, position.longitude));
  }

  void _onMarkerDragEnd(gmaps.LatLng position) {
    setState(() => _currentCenter = position);
    widget.onCenterChanged(LatLng(position.latitude, position.longitude));
  }

  void _onLocationSelected(gmaps.LatLng position, String address) {
    setState(() => _currentCenter = position);
    widget.onCenterChanged(LatLng(position.latitude, position.longitude));
    
    // Animer la caméra vers la nouvelle position
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(position, 16.0),
    );
  }
}