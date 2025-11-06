// lib/features/proches/presentation/contact_locations_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../core/models/contact_location.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/services/contact_locations_service.dart';

/// Page pour afficher les positions récentes d'un proche
class ContactLocationsPage extends StatefulWidget {
  final ContactRelation contactRelation;

  const ContactLocationsPage({
    super.key,
    required this.contactRelation,
  });

  @override
  State<ContactLocationsPage> createState() => _ContactLocationsPageState();
}

class _ContactLocationsPageState extends State<ContactLocationsPage> {
  final ContactLocationsService _locationsService = ContactLocationsService();
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _controller;
  
  List<ContactLocation> _locations = [];
  bool _isLoading = true;
  String? _error;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locations = await _locationsService.getContactLocations(
        contactId: widget.contactRelation.contact.id,
        limit: 50,
      );
      
      setState(() {
        _locations = locations;
        _isLoading = false;
      });

      // Centrer la carte sur la première position si disponible
      if (locations.isNotEmpty && _showMap) {
        _centerMapOnLocation(locations.first);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _centerMapOnLocation(ContactLocation location) async {
    try {
      GoogleMapController? controller = _controller;
      
      // Si le contrôleur n'est pas encore disponible, attendre qu'il soit complété
      if (controller == null && !_mapController.isCompleted) {
        controller = await _mapController.future;
      } else if (controller == null) {
        controller = await _mapController.future;
      }
      
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          15.0,
        ),
      );
    } catch (e) {
      print('Erreur lors du centrage de la carte: $e');
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _locations.length; i++) {
      final location = _locations[i];
      final isLatest = i == 0;
      
      markers.add(
        Marker(
          markerId: MarkerId('location_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          icon: isLatest 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: isLatest ? 'Position actuelle' : 'Position ${i + 1}',
            snippet: location.timeAgoText,
          ),
          onTap: () => _showLocationDetails(location),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_locations.length < 2) return {};
    
    final points = _locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();
    
    return {
      Polyline(
        polylineId: const PolylineId('path'),
        points: points,
        color: Theme.of(context).colorScheme.primary,
        width: 3,
        patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };
  }

  void _showLocationDetails(ContactLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de la position',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Heure', location.timeAgoText),
            _buildDetailRow('Précision', location.accuracyText),
            _buildDetailRow('Source', location.source.toUpperCase()),
            if (location.speed != null)
              _buildDetailRow('Vitesse', '${location.speed!.toStringAsFixed(1)} km/h'),
            if (location.batteryLevel != null)
              _buildDetailRow('Batterie', '${location.batteryLevel}%'),
            _buildDetailRow('Mode', location.foreground ? 'Premier plan' : 'Arrière-plan'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Positions de ${widget.contactRelation.contact.name}'),
        actions: [
          IconButton(
            onPressed: _loadLocations,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _locations.isEmpty
                  ? _buildEmptyState()
                  : _showMap
                      ? _buildMapView()
                      : _buildListView(),
    );
  }

  Widget _buildErrorState() {
    final isAuthError = _error != null &&
        (_error!.contains("403") ||
            _error!.contains("Vous n'avez pas l'autorisation"));

    if (isAuthError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Partage de position désactivé',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.contactRelation.contact.name} n\'a pas activé le partage de sa position en temps réel avec vous.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Rassurez-vous, vous recevrez toujours les alertes de sécurité importantes.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Original error state for other errors
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Section de debug
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations de debug',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Contact ID: ${widget.contactRelation.contact.id}'),
                  Text('Relation ID: ${widget.contactRelation.id}'),
                  Text('Statut: ${widget.contactRelation.status.name}'),
                  Text('Niveau de partage: ${widget.contactRelation.shareLevel.name}'),
                  Text('Peut me voir: ${widget.contactRelation.canSeeMe}'),
                  Text('Relation active: ${widget.contactRelation.isActive}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadLocations,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune position disponible',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ce proche n\'a pas encore partagé de positions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              _controller = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _locations.isNotEmpty
                  ? LatLng(_locations.first.latitude, _locations.first.longitude)
                  : const LatLng(48.8566, 2.3522), // Paris par défaut
              zoom: 15.0,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildLocationsList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return _buildLocationsList();
  }

  Widget _buildLocationsList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historique des positions (${_locations.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _locations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _locations[index];
                final isLatest = index == 0;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLatest
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    radius: 12,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLatest
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  title: Text(location.timeAgoText),
                  subtitle: Text(location.accuracyText),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (location.foreground)
                        Icon(
                          Icons.smartphone,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      if (location.foreground) const SizedBox(width: 4),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.map,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Centrer la caméra sur la position sélectionnée
                    await _centerMapOnLocation(location);
                    
                    // Si on est en mode liste, basculer vers la carte
                    if (!_showMap) {
                      setState(() {
                        _showMap = true;
                      });
                      // Attendre un peu que la carte soit affichée avant de centrer
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _centerMapOnLocation(location);
                    }
                    
                    // Afficher les détails de la position
                    _showLocationDetails(location);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}