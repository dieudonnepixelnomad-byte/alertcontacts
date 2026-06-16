import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

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

  @override
  void initState() {
    super.initState();
    _cameraPosition = gmaps.CameraPosition(
      target: widget.initialPosition,
      zoom: 17.0,
    );
    _reverseGeocode(widget.initialPosition);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.gray900,
        ),
        title: Text(
          'Lieu de l\'incident',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
          // My location FAB
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'alert_loc_my_pos',
              backgroundColor: Colors.white,
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
            child: _buildBottomPanel(tt),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(TextTheme tt) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
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
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Emplacement sélectionné',
            style: tt.bodySmall?.copyWith(
              color: AppColors.gray400,
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
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _address,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray900,
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
            style: tt.labelMedium?.copyWith(color: AppColors.gray400),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loadingAddress ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.gray200,
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
