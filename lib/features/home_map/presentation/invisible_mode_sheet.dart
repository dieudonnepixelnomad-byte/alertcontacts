import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class InvisibleModeSheet extends StatefulWidget {
  final bool isActive;
  final DateTime? invisibleUntil;
  final Future<bool> Function(int? durationMinutes) onActivate;
  final Future<bool> Function() onResume;

  const InvisibleModeSheet({
    super.key,
    required this.isActive,
    required this.onActivate,
    required this.onResume,
    this.invisibleUntil,
  });

  @override
  State<InvisibleModeSheet> createState() => _InvisibleModeSheetState();
}

class _InvisibleModeSheetState extends State<InvisibleModeSheet> {
  bool _loading = false;

  static const _options = [
    (60,   '1 heure'),
    (240,  '4 heures'),
    (0,    'Jusqu\'à réactivation'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 32, height: 3,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_off_outlined, color: AppColors.warning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode invisible', style: tt.titleSmall),
                          Text(
                            'Ta position ne sera plus partagée',
                            style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.isActive) ...[
                  _ActiveState(
                    invisibleUntil: widget.invisibleUntil,
                    loading: _loading,
                    onResume: _resume,
                  ),
                ] else ...[
                  Text(
                    'Durée',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  ..._options.map((opt) {
                    final (minutes, label) = opt;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DurationOption(
                        label: label,
                        loading: _loading,
                        onTap: () => _activate(minutes == 0 ? null : minutes),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Future<void> _activate(int? minutes) async {
    setState(() => _loading = true);
    final ok = await widget.onActivate(minutes);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'activer le mode invisible')),
        );
      }
    }
  }

  Future<void> _resume() async {
    setState(() => _loading = true);
    final ok = await widget.onResume();
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _loading = false);
      }
    }
  }
}

class _DurationOption extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _DurationOption({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: loading
            ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
            : Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _ActiveState extends StatelessWidget {
  final DateTime? invisibleUntil;
  final bool loading;
  final VoidCallback onResume;

  const _ActiveState({this.invisibleUntil, required this.loading, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final until = invisibleUntil;
    final label = until != null
        ? 'Actif jusqu\'à ${until.hour.toString().padLeft(2, '0')}h${until.minute.toString().padLeft(2, '0')}'
        : 'Actif jusqu\'à réactivation manuelle';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onResume,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    'Reprendre le partage',
                    style: tt.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Inline banner for the map overlay ───────────────────────────────────────

class InvisibleModeBanner extends StatelessWidget {
  final DateTime? invisibleUntil;
  final VoidCallback onResume;

  const InvisibleModeBanner({super.key, this.invisibleUntil, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final until = invisibleUntil;
    final label = until != null
        ? 'Mode invisible · jusqu\'à ${until.hour.toString().padLeft(2, '0')}h${until.minute.toString().padLeft(2, '0')}'
        : 'Mode invisible actif';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: tt.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: onResume,
            child: Text(
              'Reprendre',
              style: tt.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
