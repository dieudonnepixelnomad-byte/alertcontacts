import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import '../services/places_service.dart';

class LocationSearchResult {
  final LatLng coordinates;
  final String displayName;
  final String fullAddress;
  final String? placeId;

  LocationSearchResult({
    required this.coordinates,
    required this.displayName,
    required this.fullAddress,
    this.placeId,
  });
}

class LocationSearchField extends StatefulWidget {
  final String? hintText;
  final Function(LatLng, String) onLocationSelected;
  final EdgeInsetsGeometry? margin;

  const LocationSearchField({
    super.key,
    this.hintText = 'Rechercher un lieu...',
    required this.onLocationSelected,
    this.margin,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<LocationSearchResult> _searchResults = [];
  bool _showResults = false;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    // Annuler le timer précédent s'il existe
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    // Debounce de 300ms pour éviter trop d'appels API
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _isSearching = true;
      });

      try {
        final response = await PlacesService.getAutocomplete(query);
        final List<LocationSearchResult> results = [];

        if (response.status == 'OK' && response.predictions != null) {
          // Traiter les prédictions (maximum 5 résultats)
          for (final prediction in response.predictions!.take(5)) {
            if (prediction.placeId != null) {
              try {
                // Obtenir les détails du lieu pour avoir les coordonnées
                final placeDetails = await PlacesService.getPlaceDetails(
                  prediction.placeId!,
                );

                if (placeDetails?.geometry?.location != null) {
                  final location = placeDetails!.geometry!.location!;

                  // Utiliser le formatage structuré si disponible
                  String displayName = prediction.description ?? '';
                  if (prediction.structuredFormatting?.mainText != null) {
                    displayName = prediction.structuredFormatting!.mainText!;
                    if (prediction.structuredFormatting?.secondaryText !=
                        null) {
                      displayName +=
                          ', ${prediction.structuredFormatting!.secondaryText!}';
                    }
                  }

                  results.add(
                    LocationSearchResult(
                      coordinates: LatLng(location.lat, location.lng),
                      displayName: displayName,
                      fullAddress:
                          placeDetails.formattedAddress ??
                          prediction.description ??
                          '',
                      placeId: prediction.placeId,
                    ),
                  );
                }
              } catch (e, stack) {
                // En cas d'erreur pour ce lieu spécifique, passer au suivant
                FirebaseCrashlytics.instance.recordError(
                  e,
                  stack,
                  reason:
                      'Erreur lors de la récupération des détails du lieu ${prediction.placeId}',
                );
                continue;
              }
            }
          }
        } else {
          // Log si le statut n'est pas OK
          FirebaseCrashlytics.instance.recordError(
            Exception(
              'Places Autocomplete API Warning: Status=${response.status}, ErrorMessage=${response.toString()}',
            ),
            StackTrace.current,
            reason: 'Autocomplete API non-OK status',
          );
        }

        if (!mounted) return;

        setState(() {
          _searchResults = results;
          _showResults = true;
          _isSearching = false;
        });
      } catch (e, stack) {
        if (!mounted) return;

        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Erreur globale lors de la recherche de lieu pour: $query',
        );

        setState(() {
          _searchResults = [];
          _showResults = false;
          _isSearching = false;
        });
      }
    });
  }

  void _selectLocation(LocationSearchResult result) {
    _controller.text = result.displayName;

    setState(() {
      _showResults = false;
    });

    _focusNode.unfocus();

    widget.onLocationSelected(result.coordinates, result.fullAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Rechercher un lieu...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _searchResults = [];
                            _showResults = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                developer.log(
                  'Search input: $value',
                  name: 'LocationSearchField',
                );
                _searchLocation(value);
              },
              onTap: () {
                if (_searchResults.isNotEmpty) {
                  setState(() {
                    _showResults = true;
                  });
                }
              },
            ),
          ),
          if (_showResults && _searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFF006970),
                    ),
                    title: Text(
                      result.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${result.coordinates.latitude.toStringAsFixed(4)}, ${result.coordinates.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () => _selectLocation(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
