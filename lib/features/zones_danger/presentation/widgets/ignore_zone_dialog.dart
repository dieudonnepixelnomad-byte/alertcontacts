import 'package:flutter/material.dart';
import '../../../../core/models/danger_zone.dart';
import '../../../../theme/colors.dart';

class IgnoreZoneDialog extends StatefulWidget {
  final DangerZone zone;
  final Function(int? durationHours) onIgnore;

  const IgnoreZoneDialog({
    super.key,
    required this.zone,
    required this.onIgnore,
  });

  @override
  State<IgnoreZoneDialog> createState() => _IgnoreZoneDialogState();
}

class _IgnoreZoneDialogState extends State<IgnoreZoneDialog> {
  int? _selectedDuration;
  bool _isLoading = false;
  bool _hasSelectedDuration = false;

  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '1 heure', 'hours': 1},
    {'label': '4 heures', 'hours': 4},
    {'label': '24 heures', 'hours': 24},
    {'label': '1 semaine', 'hours': 24 * 7},
    {'label': 'Définitivement', 'hours': null},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.visibility_off,
            color: AppColors.alert,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ignorer cette zone'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous ne recevrez plus d\'alertes pour "${widget.zone.title}" pendant la durée sélectionnée.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Durée d\'ignorance :',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._durationOptions.map((option) => _buildDurationOption(option)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_hasSelectedDuration 
              ? null 
              : _handleIgnore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alert,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Ignorer'),
        ),
      ],
    );
  }

  Widget _buildDurationOption(Map<String, dynamic> option) {
    final hours = option['hours'] as int?;
    final label = option['label'] as String;
    // Pour l'option "Définitivement", hours est null, donc on compare différemment
    final isSelected = (hours == null && _selectedDuration == null && _hasSelectedDuration) ||
                      (hours != null && _selectedDuration == hours);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isLoading ? null : () {
          setState(() {
            _selectedDuration = hours;
            _hasSelectedDuration = true;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppColors.alert 
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
                ? AppColors.alert.withOpacity(0.1) 
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected 
                    ? AppColors.alert 
                    : Theme.of(context).colorScheme.outline,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected 
                        ? AppColors.alert 
                        : null,
                    fontWeight: isSelected ? FontWeight.w500 : null,
                  ),
                ),
              ),
              if (hours == null)
                Icon(
                  Icons.warning_amber,
                  color: AppColors.alert,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleIgnore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onIgnore(_selectedDuration);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedDuration == null
                  ? 'Zone ignorée définitivement'
                  : 'Zone ignorée pour ${_getDurationLabel(_selectedDuration!)}',
            ),
            backgroundColor: AppColors.safe,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ignorance de la zone: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  String _getDurationLabel(int hours) {
    if (hours < 24) {
      return '$hours heure${hours > 1 ? 's' : ''}';
    } else if (hours < 24 * 7) {
      final days = hours ~/ 24;
      return '$days jour${days > 1 ? 's' : ''}';
    } else {
      final weeks = hours ~/ (24 * 7);
      return '$weeks semaine${weeks > 1 ? 's' : ''}';
    }
  }
}