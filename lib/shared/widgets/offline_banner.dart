import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final int? minutesSinceUpdate;
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.minutesSinceUpdate, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cacheLabel = minutesSinceUpdate != null
        ? 'Cache · MAJ il y a ${minutesSinceUpdate}min'
        : 'Cache · données locales';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              'Pas de connexion',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(width: 1, height: 12, color: Colors.white24),
            const SizedBox(width: 6),
            Text(
              cacheLabel,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
