import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../core/models/places_autocomplete.dart';
import '../../../core/services/places_service.dart';
import '../../../theme/colors.dart';

class AlertLocationPickerPage extends StatefulWidget {
  final gmaps.LatLng initialPosition;

  const AlertLocationPickerPage({super.key, required this.initialPosition});

  @override
  State<AlertLocationPickerPage> createState() =>
      _AlertLocationPickerPageState();
}

class _AlertLocationPickerPageState extends State<AlertLocationPickerPage> {
  late gmaps.CameraPosition _cameraPosition;
  gmaps.GoogleMapController? _mapController;
  String _address = 'Chargement de l\'adresse…';
  bool _loadingAddress = false;
  Timer? _debounce;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<AutoCompletePrediction> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _searchDebounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _cameraPosition = gmaps.CameraPosition(
      target: widget.initialPosition,
      zoom: 17.0,
    );
    _reverseGeocode(widget.initialPosition);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(gmaps.LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street?.isNotEmpty == true) p.street!,
          if (p.thoroughfare?.isNotEmpty == true && p.street != p.thoroughfare)
            p.thoroughfare!,
          if (p.locality?.isNotEmpty == true) p.locality!,
        ];
        setState(
          () => _address = parts.isNotEmpty
              ? parts.join(', ')
              : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _address =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onCameraMove(gmaps.CameraPosition pos) {
    _cameraPosition = pos;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(pos.target);
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      _LocationResult(latLng: _cameraPosition.target, address: _address),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final response = await PlacesService.getAutocomplete(query);
      if (!mounted) return;
      setState(() {
        _suggestions = response.status == 'OK'
            ? (response.predictions ?? [])
            : [];
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (e) {
      log('[AlertLocationPicker] Places autocomplete error: $e');
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(AutoCompletePrediction result) async {
    _searchController.text =
        result.description ?? result.structuredFormatting?.mainText ?? '';
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });

    if (result.placeId == null) return;
    try {
      final details = await PlacesService.getPlaceDetails(result.placeId!);
      final location = details?.geometry?.location;
      if (location == null) return;
      final target = gmaps.LatLng(location.lat, location.lng);
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(target, 17),
      );
      _reverseGeocode(target);
    } catch (e) {
      log('[AlertLocationPicker] Places details error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: colorScheme.onSurface,
        ),
        title: Text(
          'Lieu de l\'incident',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: _cameraPosition,
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          // Fixed center pin
          const Center(child: _CenterPin()),
          // Search bar
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _buildSearchBar(tt, colorScheme),
          ),
          // My location FAB
          Positioned(
            right: 16,
            top: _showSuggestions
                ? 12.0 + 52 + (_suggestions.length * 56.0).clamp(0, 224) + 12
                : 12.0 + 52 + 12,
            child: FloatingActionButton.small(
              heroTag: 'alert_loc_my_pos',
              backgroundColor: colorScheme.surface,
              elevation: 2,
              onPressed: _goToMyLocation,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          // Bottom address + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(tt, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TextTheme tt, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            style: tt.bodyMedium?.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Rechercher une adresse…',
              hintStyle: tt.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              prefixIcon: _loadingSuggestions
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 20,
                    ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = [];
                          _showSuggestions = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return InkWell(
                  onTap: () => _selectSuggestion(s),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.description ??
                                s.structuredFormatting?.mainText ??
                                '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPanel(TextTheme tt, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Emplacement sélectionné',
            style: tt.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: _loadingAddress
                    ? Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _address,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Déplace la carte pour ajuster le point',
            style: tt.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loadingAddress ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirmer cet emplacement',
                style: tt.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    log('[AlertLocationPicker] _goToMyLocation: tap détecté');
    try {
      final permission = await Geolocator.checkPermission();
      log('[AlertLocationPicker] permission: $permission');
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('[AlertLocationPicker] permission refusée — abandon');
        return;
      }
      log('[AlertLocationPicker] Geolocator.getCurrentPosition en cours…');
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        log(
          '[AlertLocationPicker] getCurrentPosition timeout — fallback getLastKnownPosition',
        );
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        log('[AlertLocationPicker] aucune position disponible');
        return;
      }
      log(
        '[AlertLocationPicker] position obtenue: ${pos.latitude}, ${pos.longitude}',
      );
      final target = gmaps.LatLng(pos.latitude, pos.longitude);
      if (_mapController == null) {
        log(
          '[AlertLocationPicker] _mapController est null — carte pas encore prête',
        );
        return;
      }
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(target, 17),
      );
      log('[AlertLocationPicker] caméra animée vers position actuelle');
    } catch (e, st) {
      log(
        '[AlertLocationPicker] erreur _goToMyLocation: $e',
        error: e,
        stackTrace: st,
      );
    }
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        CustomPaint(size: const Size(2, 12), painter: _PinStemPainter()),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _PinStemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = AppColors.danger
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationResult {
  final gmaps.LatLng latLng;
  final String address;
  const _LocationResult({required this.latLng, required this.address});
}
