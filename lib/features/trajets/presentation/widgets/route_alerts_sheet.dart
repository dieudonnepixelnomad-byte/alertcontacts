import 'package:flutter/material.dart';

import '../../../../core/models/route_plan.dart';
import '../../../../theme/colors.dart';

/// Résumé compact des alertes affiché sur la carte de l'itinéraire.
///
/// Les marqueurs restent tous visibles sur la carte. Ce composant évite qu'un
/// bandeau par alerte masque la carte lorsque le trajet en rencontre plusieurs.
class RouteAlertsSummary extends StatelessWidget {
  const RouteAlertsSummary({
    super.key,
    required this.hits,
    required this.onTap,
  });

  final List<RouteIncidentHit> hits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(hits);
    final first = ordered.first;
    final count = ordered.length;

    return Material(
      color: const Color(0xEE171A1F),
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              _AlertAvatar(hit: first),
              if (count > 1)
                Transform.translate(
                  offset: const Offset(-9, 0),
                  child: _AlertAvatar(hit: ordered[1], small: true),
                ),
              Expanded(
                child: Text(
                  count == 1 ? '1 alerte sur ce trajet' : '$count alertes sur ce trajet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class RouteAlertsSheet extends StatelessWidget {
  const RouteAlertsSheet({
    super.key,
    required this.hits,
    required this.canAvoid,
    this.destinationInside = false,
    this.onAvoid,
  });

  final List<RouteIncidentHit> hits;
  final bool canAvoid;
  final bool destinationInside;
  final VoidCallback? onAvoid;

  static Future<void> show(
    BuildContext context, {
    required List<RouteIncidentHit> hits,
    required bool canAvoid,
    bool destinationInside = false,
    VoidCallback? onAvoid,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RouteAlertsSheet(
        hits: hits,
        canAvoid: canAvoid,
        destinationInside: destinationInside,
        onAvoid: onAvoid == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onAvoid();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(hits);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .66,
        ),
        decoration: const BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray600,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Alertes sur ce trajet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ordered.length}',
                    style: const TextStyle(
                      color: Color(0xFF53C6D8),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                itemCount: ordered.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.gray600),
                itemBuilder: (_, index) => _AlertListItem(
                  hit: ordered[index],
                  order: index + 1,
                ),
              ),
            ),
            if (destinationInside)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Ta destination est dans une zone signalée. Sois prudent à l’arrivée.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            if (canAvoid && onAvoid != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAvoid,
                    icon: const Icon(Icons.alt_route),
                    label: Text(
                      ordered.length == 1
                          ? 'Contourner cette alerte'
                          : 'Contourner ces alertes',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF53C6D8),
                      foregroundColor: AppColors.gray900,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  const _AlertListItem({required this.hit, required this.order});

  final RouteIncidentHit hit;
  final int order;

  @override
  Widget build(BuildContext context) {
    final incident = hit.incident;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: incident.severity.color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$order',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${incident.type.emoji} ${hit.headline}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${hit.detail} · à ${_formatDistance(hit.distanceFromOriginM)} du départ',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertAvatar extends StatelessWidget {
  const _AlertAvatar({required this.hit, this.small = false});

  final RouteIncidentHit hit;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 34.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hit.incident.severity.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gray900, width: 2),
      ),
      child: Text(hit.incident.type.emoji, style: TextStyle(fontSize: small ? 15 : 18)),
    );
  }
}

List<RouteIncidentHit> _ordered(List<RouteIncidentHit> hits) {
  return [...hits]..sort((a, b) => a.distanceFromOriginM.compareTo(b.distanceFromOriginM));
}

String _formatDistance(int meters) => meters < 1000
    ? '$meters m'
    : '${(meters / 1000).toStringAsFixed(1)} km';
