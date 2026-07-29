import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import '../../../core/models/places_autocomplete.dart';
import '../../../core/services/paywall_trigger_service.dart';
import '../../../core/services/places_service.dart';
import '../../../features/paywall/presentation/paywall_page.dart';
import '../../../theme/colors.dart';
import '../providers/zones_notifier.dart';

class ZoneCreationWizard extends StatefulWidget {
  const ZoneCreationWizard({super.key});

  @override
  State<ZoneCreationWizard> createState() => _ZoneCreationWizardState();
}

class _ZoneCreationWizardState extends State<ZoneCreationWizard> {
  int _step = 0;

  gmaps.LatLng? _selectedPosition;
  double _radius = 150;

  final _nameController = TextEditingController();
  String _selectedIcon = 'other';
  bool _saving = false;

  static const _icons = [
    ('home', Icons.home_outlined, 'Maison'),
    ('school', Icons.school_outlined, 'École'),
    ('work', Icons.work_outlined, 'Travail'),
    ('sport', Icons.sports_outlined, 'Sport'),
    ('shopping', Icons.shopping_bag_outlined, 'Shopping'),
    ('other', Icons.location_on_outlined, 'Autre'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_step > 0)
                IconButton(
                  onPressed: () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  padding: EdgeInsets.zero,
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Text(
                  ['Position & rayon', 'Nommer la zone'][_step],
                  style: tt.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        _StepIndicator(currentStep: _step),
        const SizedBox(height: 8),
        Expanded(
          child: IndexedStack(
            index: _step,
            children: [
              _StepPositionRadius(
                selectedPosition: _selectedPosition,
                radius: _radius,
                onPositionSelected: (pos) =>
                    setState(() => _selectedPosition = pos),
                onRadiusChanged: (r) => setState(() => _radius = r),
                onNext: () => setState(() => _step = 1),
              ),
              _StepMetadata(
                nameController: _nameController,
                selectedIcon: _selectedIcon,
                icons: _icons,
                onIconSelected: (icon) => setState(() => _selectedIcon = icon),
                saving: _saving,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _selectedPosition == null) return;

    final notifier = context.read<ZonesNotifier>();

    if (PaywallTriggerService.checkZoneLimit(notifier.safeZonesCount)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallPage(trigger: 'zone_limit'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    final ok = await notifier.createZone({
      'name': _nameController.text.trim(),
      'lat': _selectedPosition!.latitude,
      'lng': _selectedPosition!.longitude,
      'radius': _radius.round(),
      'icon': _selectedIcon,
      'color': '#1E6868',
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zone "${_nameController.text.trim()}" créée'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.errorMessage ?? 'Erreur lors de la création'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

// ─── Step Indicator ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(2, (i) {
          final active = i <= currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Position + Radius ───────────────────────────────────────────────

class _StepPositionRadius extends StatefulWidget {
  final gmaps.LatLng? selectedPosition;
  final double radius;
  final ValueChanged<gmaps.LatLng> onPositionSelected;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onNext;

  const _StepPositionRadius({
    required this.selectedPosition,
    required this.radius,
    required this.onPositionSelected,
    required this.onRadiusChanged,
    required this.onNext,
  });

  @override
  State<_StepPositionRadius> createState() => _StepPositionRadiusState();
}

class _StepPositionRadiusState extends State<_StepPositionRadius> {
  final _searchController = TextEditingController();
  gmaps.GoogleMapController? _mapController;
  Timer? _debounce;
  List<_PlacePrediction> _suggestions = [];
  bool _searching = false;
  bool _locating = false;
  String? _apiError;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('[Location] permission denied: $permission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 20));

      log('[Location] got position: ${pos.latitude}, ${pos.longitude}');
      final latlng = gmaps.LatLng(pos.latitude, pos.longitude);
      widget.onPositionSelected(latlng);
      _mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(latlng, 16));
    } catch (e) {
      log('[Location] getCurrentPosition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur localisation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submitSearch(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (_suggestions.isNotEmpty) {
      _selectPlace(_suggestions.first);
      return;
    }
    await _fetchSuggestions(trimmed);
    if (_suggestions.isNotEmpty) {
      _selectPlace(_suggestions.first);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() { _suggestions = []; _apiError = null; });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _fetchSuggestions(value.trim()),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    log('[Places] search query="$input"');
    setState(() { _searching = true; _apiError = null; });
    try {
      final response = await PlacesService.getAutocomplete(input);
      log('[Places] status=${response.status}');
      if (!mounted) return;
      final predictions = (response.status == 'OK'
              ? response.predictions ?? []
              : <AutoCompletePrediction>[])
          .where((p) => p.placeId != null)
          .map((p) => _PlacePrediction(
                mainText: p.structuredFormatting?.mainText ??
                    p.description ??
                    '',
                secondaryText: p.structuredFormatting?.secondaryText ?? '',
                placeId: p.placeId!,
              ))
          .toList();
      setState(() => _suggestions = predictions);
    } catch (e) {
      log('[Places] error: $e');
      if (mounted) setState(() => _apiError = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectPlace(_PlacePrediction place) async {
    log('[Places] selected placeId=${place.placeId}');
    _searchController.text = place.mainText;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
    try {
      final details = await PlacesService.getPlaceDetails(place.placeId);
      final location = details?.geometry?.location;
      if (location == null) return;
      final pos = gmaps.LatLng(location.lat, location.lng);
      widget.onPositionSelected(pos);
      _mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(pos, 16));
    } catch (e) {
      log('[Places] details error: $e');
      if (mounted) setState(() => _apiError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasPos = widget.selectedPosition != null;
    final showSuggestions = _suggestions.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              gmaps.GoogleMap(
                initialCameraPosition: const gmaps.CameraPosition(
                  target: gmaps.LatLng(48.8566, 2.3522),
                  zoom: 14,
                ),
                onMapCreated: (ctrl) => _mapController = ctrl,
                onTap: (pos) {
                  widget.onPositionSelected(pos);
                  setState(() => _suggestions = []);
                  FocusScope.of(context).unfocus();
                },
                markers: hasPos
                    ? {
                        gmaps.Marker(
                          markerId: const gmaps.MarkerId('zone_center'),
                          position: widget.selectedPosition!,
                          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                            gmaps.BitmapDescriptor.hueAzure,
                          ),
                        ),
                      }
                    : {},
                circles: hasPos
                    ? {
                        gmaps.Circle(
                          circleId: const gmaps.CircleId('zone_preview'),
                          center: widget.selectedPosition!,
                          radius: widget.radius,
                          strokeColor: AppColors.primary,
                          strokeWidth: 2,
                          fillColor: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      }
                    : {},
              ),
              Positioned(
                bottom: 115,
                right: 10,
                child: FloatingActionButton.small(
                  onPressed: _locating ? null : _goToCurrentLocation,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  heroTag: 'zone_my_location',
                  child: _locating
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 20),
                ),
              ),
              if (!hasPos && !showSuggestions)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 52,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Recherche une adresse ou appuie sur la carte',
                        style: tt.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // Search field + dropdown overlay
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _submitSearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une adresse…',
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_apiError != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Places API: $_apiError',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    if (showSuggestions)
                      Material(
                        elevation: 8,
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            itemBuilder: (_, i) {
                              final s = _suggestions[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                title: Text(
                                  s.mainText,
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                subtitle: s.secondaryText.isNotEmpty
                                    ? Text(
                                        s.secondaryText,
                                        style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      )
                                    : null,
                                onTap: () => _selectPlace(s),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Radius controls
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rayon', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(
                '${widget.radius.toInt()} m',
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Slider(
          value: widget.radius,
          min: 50,
          max: 500,
          divisions: 45,
          activeColor: AppColors.primary,
          onChanged: widget.onRadiusChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: hasPos ? widget.onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Theme.of(context).colorScheme.outlineVariant,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Suivant',
                style: tt.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlacePrediction {
  final String mainText;
  final String secondaryText;
  final String placeId;

  const _PlacePrediction({
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });
}

// ─── Step 2: Metadata ────────────────────────────────────────────────────────

class _StepMetadata extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedIcon;
  final List<(String, IconData, String)> icons;
  final ValueChanged<String> onIconSelected;
  final bool saving;
  final VoidCallback onSubmit;

  const _StepMetadata({
    required this.nameController,
    required this.selectedIcon,
    required this.icons,
    required this.onIconSelected,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Nom de la zone', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'Ex : Maison, École des enfants…',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          Text('Icône', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: icons.map((entry) {
              final (id, iconData, label) = entry;
              final selected = selectedIcon == id;
              return GestureDetector(
                onTap: () => onIconSelected(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        size: 18,
                        color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: tt.bodySmall?.copyWith(
                          color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Theme.of(context).colorScheme.outlineVariant,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Créer la zone',
                      style: tt.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
