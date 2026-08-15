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
        // §11.2 — couleur de gravité en fond à 10 %
        color: severityColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severityColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hit.headline,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            destinationInside
                ? 'Ta destination est dans la zone signalée. Sois prudent à l\'arrivée.'
                : hit.detail,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
}
