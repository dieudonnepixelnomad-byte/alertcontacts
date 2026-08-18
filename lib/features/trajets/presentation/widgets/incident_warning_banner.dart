import 'package:flutter/material.dart';

import '../../../../core/models/route_plan.dart';

/// Bandeau d'avertissement avant le départ — CDC V4.1 §5.4 étape 4
///
/// N'apparaît que s'il y a un HIT. Le cas majoritaire — aucun incident sur le
/// trajet — n'affiche rien du tout.
///
/// Wording contraint (§6.7) : « Alerte signalée », « Signalé par N personnes ».
/// Jamais « danger », jamais « trajet dangereux ». Le §1.1 pose que
/// l'application vend de la tranquillité d'esprit ; un vocabulaire anxiogène
/// travaille contre le positionnement.
class IncidentWarningBanner extends StatelessWidget {
  const IncidentWarningBanner({
    super.key,
    required this.hit,
    required this.onAvoid,
    required this.onContinue,
    this.canAvoid = true,
    this.destinationInside = false,
  });

  final RouteIncidentHit hit;
  final VoidCallback onAvoid;
  final VoidCallback onContinue;

  /// §5.6 — quand la destination est dans la zone, HERE documente que la route
  /// la traversera : on ne propose pas de contournement, on prévient.
  final bool canAvoid;
  final bool destinationInside;

  @override
  Widget build(BuildContext context) {
    final severityColor = hit.incident.severity.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171A1F),
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: severityColor, width: 5)),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
              child: Center(child: Text(hit.incident.type.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              hit.headline,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            )),
          ]),
          const SizedBox(height: 6),
          Text(
            '${hit.detail} · à ${_formatDistance(hit.distanceFromOriginM)} du départ',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (destinationInside) ...[
            const SizedBox(height: 4),
            Text(
            destinationInside
                ? 'Ta destination est dans la zone signalée. Sois prudent à l\'arrivée.'
                : '',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          )],
          const SizedBox(height: 12),
          // §11.3 — boutons décisionnels en zone basse du bandeau, pleine largeur
          Row(
            children: [
              if (canAvoid && !destinationInside) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: onAvoid,
                    style: FilledButton.styleFrom(
                      backgroundColor: severityColor,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Contourner'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDistance(int meters) => meters < 1000
      ? '$meters m'
      : '${(meters / 1000).toStringAsFixed(1)} km';
}
