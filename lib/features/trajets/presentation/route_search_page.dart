import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../../core/models/places_autocomplete.dart';
import '../../../core/models/route_plan.dart';
import '../../../core/services/api_routes_service.dart';
import '../../../core/services/places_service.dart';
import '../../../theme/colors.dart';
import '../providers/route_provider.dart';

/// Résultat de l'écran de recherche — CDC V4.1 §6.2
class RouteSearchResult {
  const RouteSearchResult({
    required this.origin,
    required this.destination,
    required this.transportMode,
    this.originLabel,
    this.destinationLabel,
  });

  final gmaps.LatLng origin;
  final gmaps.LatLng destination;
  final String? originLabel;
  final String? destinationLabel;
  final TransportMode transportMode;
}

/// Écran de recherche d'itinéraire — CDC V4.1 §6.2
class RouteSearchPage extends StatefulWidget {
  const RouteSearchPage({
    super.key,
    this.initialOrigin,
    this.initialOriginLabel,
    this.initialDestination,
    this.initialDestinationLabel,
  });

  final gmaps.LatLng? initialOrigin;
  final String? initialOriginLabel;
  final gmaps.LatLng? initialDestination;
  final String? initialDestinationLabel;

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  /// §6.2 / §5.4 étape 1 — sans debounce, chaque frappe génère une requête
  /// facturée à l'API d'autocomplétion.
  static const Duration _debounce = Duration(milliseconds: 300);
  static const int _minQueryLength = 3;

  final TextEditingController _originController = TextEditingController(text: 'Ma position');
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  Timer? _debounceTimer;
  List<AutoCompletePrediction> _predictions = const [];
  bool _isSearching = false;

  /// Champ actuellement édité — détermine où appliquer la prédiction choisie.
  bool _searchingOrigin = false;

  gmaps.LatLng? _origin;
  gmaps.LatLng? _destination;
  String? _destinationLabel;
  TransportMode _transportMode = TransportMode.car;

  /// true tant que le champ Départ vaut « Ma position ».
  bool _originIsCurrentPosition = true;

  @override
  void initState() {
    super.initState();

    _origin = widget.initialOrigin;
    _destination = widget.initialDestination;
    _destinationLabel = widget.initialDestinationLabel;

    if (widget.initialOriginLabel != null) {
      _originController.text = widget.initialOriginLabel!;
      _originIsCurrentPosition = widget.initialOriginLabel == 'Ma position';
    }
    if (widget.initialDestinationLabel != null) {
      _destinationController.text = widget.initialDestinationLabel!;
    }

    _resolveCurrentPositionIfNeeded();

    // §6.2 — focus automatique sur Arrivée à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _destinationFocus.requestFocus();
      context.read<RouteProvider>().loadRecentDestinations();
    });

    _originFocus.addListener(() {
      if (_originFocus.hasFocus && _originIsCurrentPosition) {
        _originController.clear();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentPositionIfNeeded() async {
    if (_origin != null) return;

    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
          ).timeout(const Duration(seconds: 8));

      if (mounted && _originIsCurrentPosition) {
        setState(() => _origin = gmaps.LatLng(position.latitude, position.longitude));
      }
    } catch (_) {
      // §9.1 — position indisponible : l'écran reste utilisable, l'utilisateur
      // peut saisir un départ à la main.
    }
  }

  void _onOriginChanged(String value) {
    setState(() {
      // Le texte peut être modifié après une sélection. Dans ce cas la
      // coordonnée précédemment choisie ne représente plus ce champ.
      _origin = null;
      _originIsCurrentPosition = false;
    });
    _searchingOrigin = true;
    _onQueryChanged(value);
  }

  void _onDestinationChanged(String value) {
    setState(() {
      // Évite de calculer un trajet vers une ancienne destination après que
      // l'utilisateur a modifié son libellé.
      _destination = null;
      _destinationLabel = null;
    });
    _searchingOrigin = false;
    _onQueryChanged(value);
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();

    if (value.trim().length < _minQueryLength) {
      setState(() => _predictions = const []);
      return;
    }

    _debounceTimer = Timer(_debounce, () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);

    try {
      final response = await PlacesService.getAutocomplete(query);

      if (mounted) {
        setState(() => _predictions = response.predictions ?? const []);
      }
    } catch (_) {
      if (mounted) setState(() => _predictions = const []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectPrediction(AutoCompletePrediction prediction) async {
    final placeId = prediction.placeId;

    if (placeId == null) return;

    setState(() => _isSearching = true);

    try {
      final details = await PlacesService.getPlaceDetails(placeId);
      final location = details?.geometry?.location;

      if (location == null) return;

      final position = gmaps.LatLng(location.lat, location.lng);
      final label = prediction.description ?? details?.formattedAddress ?? '';

      if (_searchingOrigin) {
        _applyOrigin(position, label);
      } else {
        _applyDestination(position, label);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adresse introuvable. Réessaie.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _applyOrigin(gmaps.LatLng position, String label) {
    setState(() {
      _origin = position;
      _originIsCurrentPosition = false;
      _originController.text = label;
      _predictions = const [];
    });
  }

  void _applyDestination(gmaps.LatLng position, String label) {
    setState(() {
      _destination = position;
      _destinationLabel = label;
      _destinationController.text = label;
      _predictions = const [];
    });
  }

  void _swap() {
    if (_origin == null || _destination == null) return;

    setState(() {
      final previousOrigin = _origin;
      final previousOriginLabel = _originController.text;

      _origin = _destination;
      _originController.text = _destinationLabel ?? 'Point de départ';
      _originIsCurrentPosition = false;

      _destination = previousOrigin;
      _destinationLabel = previousOriginLabel;
      _destinationController.text = previousOriginLabel;
    });
  }

  void _submit() {
    final origin = _origin;
    final destination = _destination;

    if (origin == null || destination == null) return;

    Navigator.of(context).pop(RouteSearchResult(
      origin: origin,
      destination: destination,
      originLabel: _originIsCurrentPosition ? 'Ma position' : _originController.text,
      destinationLabel: _destinationLabel,
      transportMode: _transportMode,
    ));
  }

  bool get _canSubmit => _origin != null && _destination != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final recent = context.watch<RouteProvider>().recentDestinations;

    return Scaffold(
      appBar: AppBar(title: const Text('Itinéraire')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _Field(
                          controller: _originController,
                          focusNode: _originFocus,
                          icon: Icons.my_location,
                          hint: 'Point de départ',
                          onChanged: _onOriginChanged,
                        ),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _destinationController,
                          focusNode: _destinationFocus,
                          icon: Icons.place_outlined,
                          hint: 'Où veux-tu aller ?',
                          onChanged: _onDestinationChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('route_search_swap_button'),
                    onPressed: _canSubmit ? _swap : null,
                    icon: const Icon(Icons.swap_vert),
                    tooltip: 'Inverser départ et arrivée',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _TransportModeSelector(
              selected: _transportMode,
              onChanged: (mode) => setState(() => _transportMode = mode),
            ),
            const SizedBox(height: 8),
            if (_isSearching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _predictions.isNotEmpty
                  ? ListView.builder(
                      itemCount: _predictions.length,
                      itemBuilder: (_, index) {
                        final prediction = _predictions[index];

                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            prediction.structuredFormatting?.mainText ??
                                prediction.description ??
                                '',
                          ),
                          subtitle: Text(
                            prediction.structuredFormatting?.secondaryText ?? '',
                          ),
                          onTap: () => _selectPrediction(prediction),
                        );
                      },
                    )
                  : _searchingOrigin
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _originController.text.isEmpty
                                  ? "D'où pars-tu ?"
                                  : 'Aucune adresse trouvée.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
                            ),
                          ),
                        )
                      : _RecentDestinations(
                          destinations: recent,
                          onSelect: (destination) =>
                              _applyDestination(destination.position, destination.label),
                          emptyLabel: _destinationController.text.isEmpty
                              ? 'Où veux-tu aller ?'
                              : 'Aucune adresse trouvée.',
                          textColor: colors.onSurfaceVariant,
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('route_search_submit_button'),
                  onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Voir les itinéraires'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icon;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Segmenté 🚗 Voiture · 🚶 À pied · 🛵 Deux-roues — §6.2
class _TransportModeSelector extends StatelessWidget {
  const _TransportModeSelector({required this.selected, required this.onChanged});

  final TransportMode selected;
  final ValueChanged<TransportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<TransportMode>(
        segments: TransportMode.values
            .map((mode) => ButtonSegment<TransportMode>(
                  value: mode,
                  label: Text('${mode.emoji} ${mode.label}'),
                ))
            .toList(),
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Cinq dernières destinations — §6.2
class _RecentDestinations extends StatelessWidget {
  const _RecentDestinations({
    required this.destinations,
    required this.onSelect,
    required this.emptyLabel,
    required this.textColor,
  });

  final List<RecentDestination> destinations;
  final ValueChanged<RecentDestination> onSelect;
  final String emptyLabel;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: textColor),
          ),
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Destinations récentes',
            style: TextStyle(fontSize: 13, color: textColor),
          ),
        ),
        ...destinations.map((destination) => ListTile(
              leading: const Icon(Icons.history, color: AppColors.gray400),
              title: Text(destination.label),
              onTap: () => onSelect(destination),
            )),
      ],
    );
  }
}
