import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/models/incident.dart';
import '../../../core/models/route_plan.dart';
import '../../../core/providers/map_type_notifier.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/map_type_toggle_button.dart';
import '../../../theme/colors.dart';
import '../providers/route_provider.dart';
import 'route_search_page.dart';
import 'widgets/route_alerts_sheet.dart';
import 'widgets/route_option_sheet.dart';

/// Aperçu de l'itinéraire — CDC V4.1 §6.3
///
/// La valeur d'AlertContacts n'est pas de guider mais de **prévenir avant de
/// partir et de veiller pendant le trajet** (§5.1). Il n'y a donc ni guidage
/// turn-by-turn ni voix : le suivi reste volontairement sur cette carte.
class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({super.key, required this.search});

  final RouteSearchResult search;

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  GoogleMapController? _mapController;
  late TransportMode _transportMode;
  final Map<String, BitmapDescriptor> _incidentMarkerIcons = {};
  final Set<String> _incidentMarkerIconsLoading = {};

  @override
  void initState() {
    super.initState();
    _transportMode = widget.search.transportMode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<RouteProvider>();

    final preview = await provider.loadPreview(
      origin: widget.search.origin,
      destination: widget.search.destination,
      originLabel: widget.search.originLabel,
      destinationLabel: widget.search.destinationLabel,
      transportMode: _transportMode,
    );

    if (preview == null || !mounted) return;

    AnalyticsService().logRoutePreviewed(
      transportMode: widget.search.transportMode.value,
      incidentCount: preview.incidentsOnRoute.length,
    );

    if (preview.hasIncidents) {
      final first = preview.incidentsOnRoute.first.incident;

      AnalyticsService().logRouteIncidentDetected(
        gravity: first.severity.value,
        type: first.type.value,
        reportCount: first.reportCount,
      );
    }

    _fitBounds();
  }

  void _changeTransportMode(TransportMode mode) {
    if (mode == _transportMode) return;
    setState(() {
      _transportMode = mode;
    });
    _load();
  }

  void _fitBounds() {
    final points = context.read<RouteProvider>().activePoints;

    if (points.isEmpty || _mapController == null) return;

    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          ),
        ),
        64,
      ),
    );
  }

  /// §5.4 étape 5 — le second appel au moteur n'a lieu qu'ici, sur tap explicite.
  Future<void> _avoid() async {
    final provider = context.read<RouteProvider>();
    final incidentIds = provider.avoidableIncidents
        .map((h) => h.incident.id)
        .toList();

    AnalyticsService().logRouteAvoidanceRequested(
      incidentCount: incidentIds.length,
    );

    final result = await provider.avoidIncidents(incidentIds);

    if (!mounted) return;

    final quotaBlock = provider.quotaBlock;

    if (quotaBlock != null) {
      // §10.4 — le mur apparaît au pic de motivation
      AnalyticsService().logPaywallDisplayed(trigger: 'avoidance_quota');
      _showQuotaPaywall(quotaBlock.message);
      return;
    }

    if (result == null) {
      _snack(
        provider.errorMessage ?? 'Contournement impossible pour le moment.',
      );
      return;
    }

    if (result.avoidancePartial) {
      AnalyticsService().logRouteAvoidancePartial();
    }

    _fitBounds();

    await RouteOptionSheet.show(
      context,
      options: result.options,
      selectedIndex: provider.selectedOptionIndex,
      onSelect: (index) async {
        await provider.selectOption(index);
        if (mounted) _fitBounds();
      },
      message: result.message,
    );
  }

  Future<void> _start() async {
    final provider = context.read<RouteProvider>();
    final started = await provider.startRoute();

    if (!mounted) return;

    if (!started) {
      _snack('Impossible de démarrer ce trajet pour le moment.');
      return;
    }

    AnalyticsService().logRouteStarted(
      transportMode: widget.search.transportMode.value,
      avoidanceApplied: provider.route?.avoidanceApplied ?? false,
    );

    _snack('Suivi du trajet démarré.');
  }

  Future<void> _stop() async {
    final provider = context.read<RouteProvider>();
    final stopped = await provider.endRoute();

    if (!mounted) return;

    if (!stopped) {
      _snack('Impossible d’arrêter le suivi du trajet pour le moment.');
      return;
    }

    _snack('Suivi du trajet arrêté.');
  }

  void _showQuotaPaywall(String message) {
    final provider = context.read<RouteProvider>();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contournements illimités',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                'Le contournement d\'une alerte de gravité élevée reste gratuit et illimité.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Passer à Solo — 4,99 €'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(provider.clearQuotaBlock);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteProvider>();
    final route = provider.route;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.search.origin,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: context.watch<MapTypeNotifier>().type,
            polylines: _buildPolylines(provider),
            markers: _buildMarkers(provider),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _RouteHeader(
              origin: widget.search.originLabel ?? 'Votre position',
              destination: widget.search.destinationLabel ?? 'Destination',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 138,
            right: 16,
            child: const MapTypeToggleButton(),
          ),
          if (route != null && provider.hasIncidents)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 16,
              right: 86,
              child: RouteAlertsSummary(
                hits: provider.incidentsOnRoute,
                onTap: () => RouteAlertsSheet.show(
                  context,
                  hits: provider.incidentsOnRoute,
                  canAvoid:
                      provider.hasAvoidableIncidents &&
                      !(provider.preview?.destinationInside ?? false) &&
                      !provider.isActive,
                  destinationInside:
                      provider.preview?.destinationInside ?? false,
                  onAvoid: _avoid,
                ),
              ),
            ),
          if (provider.status == RouteFlowStatus.loading ||
              provider.status == RouteFlowStatus.avoiding)
            const LinearProgressIndicator(minHeight: 3),
          if (provider.errorMessage != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: _OfflineBanner(message: provider.errorMessage!),
            ),
          if (route != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomCard(
                route: route,
                optionCount: provider.options.length,
                selectedMode: _transportMode,
                onModeChanged: _changeTransportMode,
                onStart: _start,
                onStop: _stop,
                onShowOptions: provider.options.length < 2
                    ? null
                    : () => RouteOptionSheet.show(
                        context,
                        options: provider.options,
                        selectedIndex: provider.selectedOptionIndex,
                        onSelect: (index) async {
                          await provider.selectOption(index);
                          if (mounted) _fitBounds();
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// §11.1 — tracé sélectionné teal en trait plein. Les alternatives gardent
  /// la même couleur pour appartenir au même trajet, mais passent en pointillés
  /// afin de rester identifiables sans concurrencer le choix actif.
  /// Contournant : liseré vert sous le tracé sélectionné.
  Set<Polyline> _buildPolylines(RouteProvider provider) {
    final polylines = <Polyline>{};

    for (final option in provider.options) {
      final isSelected = option.index == provider.selectedOptionIndex;
      final points = option.points;

      if (points.length < 2) continue;

      if (isSelected && option.safety == RouteSafety.avoids) {
        // Liseré vert sous le tracé principal
        polylines.add(
          Polyline(
            polylineId: PolylineId('halo_${option.index}'),
            points: points,
            color: AppColors.success,
            width: 10,
          ),
        );
      }

      polylines.add(
        Polyline(
          polylineId: PolylineId('route_${option.index}'),
          points: points,
          color: AppColors.primary,
          width: isSelected ? 6 : 5,
          zIndex: isSelected ? 2 : 1,
          patterns: isSelected
              ? const <PatternItem>[]
              : <PatternItem>[PatternItem.dash(18), PatternItem.gap(10)],
        ),
      );
    }

    if (polylines.isEmpty) {
      final points = provider.activePoints;

      if (points.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_main'),
            points: points,
            color: AppColors.primary,
            width: 6,
          ),
        );
      }
    }

    return polylines;
  }

  Set<Marker> _buildMarkers(RouteProvider provider) {
    for (final hit in provider.incidentsOnRoute) {
      _ensureIncidentMarker(hit.incident);
    }
    return {
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.search.destination,
      ),
      for (final hit in provider.incidentsOnRoute)
        Marker(
          markerId: MarkerId('route_incident_${hit.incident.id}'),
          position: hit.incident.position,
          // Le repère par défaut évite que l'alerte soit invisible pendant la
          // génération asynchrone de son icône personnalisée.
          icon:
              _incidentMarkerIcons['${hit.incident.type.value}_${hit.incident.severity.value}'] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(.5, .5),
          zIndex: 5,
          infoWindow: InfoWindow(
            title: hit.headline,
            snippet:
                '${hit.detail} · à ${_formatIncidentDistance(hit.distanceFromOriginM)} du départ',
          ),
        ),
    };
  }

  static String _formatIncidentDistance(int meters) =>
      meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(1)} km';

  void _ensureIncidentMarker(Incident incident) {
    final key = '${incident.type.value}_${incident.severity.value}';
    if (_incidentMarkerIcons.containsKey(key) ||
        !_incidentMarkerIconsLoading.add(key))
      return;
    unawaited(
      _makeIncidentMarker(incident)
          .then((icon) {
            if (mounted) setState(() => _incidentMarkerIcons[key] = icon);
          })
          .whenComplete(() => _incidentMarkerIconsLoading.remove(key)),
    );
  }

  Future<BitmapDescriptor> _makeIncidentMarker(Incident incident) async {
    const size = 62.0;
    const center = Offset(31, 31);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    canvas.drawCircle(
      const Offset(31, 34),
      24,
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(center, 24, Paint()..color = incident.severity.color);
    canvas.drawCircle(center, 21, Paint()..color = Colors.white);
    final painter = TextPainter(
      text: TextSpan(
        text: incident.type.emoji,
        style: const TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
    final image = await recorder.endRecording().toImage(62, 62);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}

/// §9.1 — hors ligne : bandeau non bloquant, jamais d'écran d'erreur.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray900.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

/// Bottom card — durée · distance · heure d'arrivée estimée (§6.3)
class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.route,
    required this.optionCount,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onStart,
    required this.onStop,
    this.onShowOptions,
  });

  final RoutePlan route;
  final int optionCount;
  final TransportMode selectedMode;
  final ValueChanged<TransportMode> onModeChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback? onShowOptions;

  @override
  Widget build(BuildContext context) {
    final arrival = route.estimatedArrival;

    return Material(
      color: AppColors.gray900,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    selectedMode.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.tune, color: Colors.white70),
                  const SizedBox(width: 18),
                  const Icon(Icons.share_outlined, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 12),
              _ModeTabs(selected: selectedMode, onChanged: onModeChanged),
              const Divider(color: AppColors.gray600, height: 24),
              Text(
                '${_formatDuration(route.durationS)} (${_formatDistance(route.distanceM)})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Arrivée ${_formatTime(arrival)} · ${route.alternatives.isNotEmpty ? route.alternatives.first.label : 'itinéraire principal'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (route.avoidanceApplied) ...[
                const SizedBox(height: 6),
                Text(
                  route.avoidancePartial
                      ? '⚠️ Contournement partiel'
                      : '✅ Contourne la zone signalée',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
              if (onShowOptions != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onShowOptions,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text('Voir les $optionCount itinéraires'),
                ),
              ],
              const SizedBox(height: 10),
              // §11.3 — CTA principal en zone basse, pleine largeur.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: route.status == 'active'
                      ? onStop
                      : route.status == 'planned'
                      ? onStart
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: route.status == 'active'
                        ? AppColors.gravityHigh
                        : const Color(0xFF53C6D8),
                    foregroundColor: route.status == 'active'
                        ? Colors.white
                        : AppColors.gray900,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(switch (route.status) {
                    'active' => 'Arrêter le suivi',
                    'completed' => 'Suivi arrêté',
                    'cancelled' => 'Trajet annulé',
                    _ => 'Démarrer',
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();

    if (minutes < 60) return '$minutes min';

    return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
  }

  static String _formatDistance(int meters) {
    return meters < 1000
        ? '$meters m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({
    required this.origin,
    required this.destination,
    required this.onBack,
  });
  final String origin;
  final String destination;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.gray900,
    elevation: 6,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Icon(Icons.my_location, color: Color(0xFF53C6D8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Divider(color: AppColors.gray600, height: 1),
                ),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.selected, required this.onChanged});
  final TransportMode selected;
  final ValueChanged<TransportMode> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: TransportMode.values.map((mode) {
      final active = mode == selected;
      final icon = switch (mode) {
        TransportMode.car => Icons.directions_car,
        TransportMode.pedestrian => Icons.directions_walk,
        TransportMode.scooter => Icons.two_wheeler,
      };
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: active ? const Color(0xFF53C6D8) : Colors.white54,
                  size: 21,
                ),
                const SizedBox(height: 3),
                Text(
                  mode.label,
                  style: TextStyle(
                    color: active ? const Color(0xFF53C6D8) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  width: 38,
                  color: active ? const Color(0xFF53C6D8) : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
