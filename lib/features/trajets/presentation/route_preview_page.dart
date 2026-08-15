import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/models/route_plan.dart';
import '../../../core/providers/map_type_notifier.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/map_type_toggle_button.dart';
import '../../../theme/colors.dart';
import '../providers/route_provider.dart';
import 'route_search_page.dart';
import 'widgets/incident_warning_banner.dart';
import 'widgets/route_option_sheet.dart';

/// Aperçu de l'itinéraire — CDC V4.1 §6.3
///
/// La valeur d'AlertContacts n'est pas de guider mais de **prévenir avant de
/// partir et de veiller pendant le trajet** (§5.1). Il n'y a donc ni guidage
/// turn-by-turn ni voix : cet écran s'arrête à « Démarrer ».
class RoutePreviewPage extends StatefulWidget {
  const RoutePreviewPage({super.key, required this.search});

  final RouteSearchResult search;

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  GoogleMapController? _mapController;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<RouteProvider>();

    final preview = await provider.loadPreview(
      origin: widget.search.origin,
      destination: widget.search.destination,
      originLabel: widget.search.originLabel,
      destinationLabel: widget.search.destinationLabel,
      transportMode: widget.search.transportMode,
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
    final incidentIds = provider.incidentsOnRoute
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

    setState(() => _bannerDismissed = true);
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

    Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Text(widget.search.destinationLabel ?? 'Itinéraire'),
      ),
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
            circles: _buildIncidentHalos(provider),
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.search.destination,
              ),
            },
          ),
          Positioned(
            top: 12,
            right: 16,
            child: const MapTypeToggleButton(),
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
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.hasIncidents && !_bannerDismissed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IncidentWarningBanner(
                        hit: provider.incidentsOnRoute.first,
                        canAvoid: provider.preview?.canAvoid ?? false,
                        destinationInside:
                            provider.preview?.destinationInside ?? false,
                        onAvoid: _avoid,
                        onContinue: () =>
                            setState(() => _bannerDismissed = true),
                      ),
                    ),
                  _BottomCard(
                    route: route,
                    optionCount: provider.options.length,
                    onStart: _start,
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// §11.1 — tracé sélectionné teal trait plein, alternatives gris 40 %.
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
          color: isSelected
              ? AppColors.primary
              : AppColors.gray400.withValues(alpha: 0.4),
          width: isSelected ? 6 : 4,
          zIndex: isSelected ? 2 : 1,
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

  /// §4.4 — le halo exprime l'incertitude, jamais la géométrie d'évitement.
  Set<Circle> _buildIncidentHalos(RouteProvider provider) {
    return provider.incidentsOnRoute.map((hit) {
      final incident = hit.incident;

      return Circle(
        circleId: CircleId('incident_${incident.id}'),
        center: incident.position,
        radius: incident.displayRadiusM.toDouble(),
        fillColor: incident.severity.color.withValues(alpha: 0.15),
        strokeColor: incident.severity.color,
        strokeWidth: 2,
      );
    }).toSet();
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
    required this.onStart,
    this.onShowOptions,
  });

  final RoutePlan route;
  final int optionCount;
  final VoidCallback onStart;
  final VoidCallback? onShowOptions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final arrival = route.estimatedArrival;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(route.durationS),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_formatDistance(route.distanceM)} · arrivée ${_formatTime(arrival)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (route.avoidanceApplied) ...[
              const SizedBox(height: 6),
              Text(
                route.avoidancePartial
                    ? '⚠️ Contournement partiel'
                    : '✅ Contourne la zone signalée',
                style: const TextStyle(fontSize: 13),
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
            // §11.3 — CTA principal en zone basse, pleine largeur
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Démarrer'),
              ),
            ),
          ],
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
