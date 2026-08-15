import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/providers/map_type_notifier.dart';
import '../../theme/colors.dart';

/// Bouton flottant affiché sur chaque carte de l'app pour changer de fond
/// de plan (normal, satellite, hybride, terrain). Le choix est partagé et
/// mémorisé via [MapTypeNotifier].
class MapTypeToggleButton extends StatelessWidget {
  const MapTypeToggleButton({super.key});

  static const _options = <MapType, (String, IconData)>{
    MapType.normal: ('Standard', Icons.map_outlined),
    MapType.hybrid: ('Hybride', Icons.layers_outlined),
    MapType.satellite: ('Satellite', Icons.satellite_alt_outlined),
    MapType.terrain: ('Terrain', Icons.terrain_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MapTypeNotifier>();
    final current = _options[notifier.type] ?? _options[MapType.hybrid]!;

    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: PopupMenuButton<MapType>(
        tooltip: 'Type de carte',
        icon: Icon(current.$2, color: AppColors.primary, size: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (type) => context.read<MapTypeNotifier>().setType(type),
        itemBuilder: (context) => _options.entries
            .map(
              (entry) => PopupMenuItem<MapType>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      entry.value.$2,
                      size: 20,
                      color: entry.key == notifier.type
                          ? AppColors.primary
                          : AppColors.gray400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value.$1,
                      style: TextStyle(
                        fontWeight: entry.key == notifier.type
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: entry.key == notifier.type
                            ? AppColors.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
