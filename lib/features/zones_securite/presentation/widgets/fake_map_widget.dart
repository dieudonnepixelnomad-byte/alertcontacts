// lib/features/zones_securite/presentation/widgets/fake_map_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/models/safe_zone.dart';

class FakeMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialRadius;
  final ValueChanged<LatLng> onCenterChanged;
  final ValueChanged<double> onRadiusChanged;

  const FakeMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialRadius,
    required this.onCenterChanged,
    required this.onRadiusChanged,
  });

  @override
  State<FakeMapWidget> createState() => _FakeMapWidgetState();
}

class _FakeMapWidgetState extends State<FakeMapWidget> {
  late LatLng _center;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _radius = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Stack(
        children: [
          // cercle (visuel)
          Center(
            child: Container(
              width: (_radius / 2), // échelle symbolique
              height: (_radius / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.12),
                border: Border.all(color: cs.primary, width: 2),
              ),
            ),
          ),
          // “pin” draggable
          Center(
            child: Draggable(
              feedback: _pin(),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                // on bouge le “centre” de façon symbolique (fake)
                final dx = details.offset.dx;
                final dy = details.offset.dy;
                // petit delta converti en coordonnées fake
                _center = LatLng(
                  _center.lat + dy / 10000.0,
                  _center.lng + dx / 10000.0,
                );
                widget.onCenterChanged(_center);
                setState(() {});
              },
              child: _pin(),
            ),
          ),
          // slider rayon (en overlay bas)
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Row(
              children: [
                const Text('Rayon'),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: '${_radius.toStringAsFixed(0)} m',
                    onChanged: (v) {
                      _radius = v;
                      widget.onRadiusChanged(_radius);
                      setState(() {});
                    },
                  ),
                ),
                Text('${_radius.toStringAsFixed(0)} m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pin() =>
      const Icon(Icons.location_on, size: 36, color: Color(0xFF006970));
}
