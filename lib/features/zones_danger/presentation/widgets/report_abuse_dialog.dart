import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class ReportAbuseDialog extends StatefulWidget {
  final String zoneId;
  final String zoneTitle;
  final Function(String reason) onReport;

  const ReportAbuseDialog({
    super.key,
    required this.zoneId,
    required this.zoneTitle,
    required this.onReport,
  });

  @override
  State<ReportAbuseDialog> createState() => _ReportAbuseDialogState();
}

class _ReportAbuseDialogState extends State<ReportAbuseDialog> {
  String? _selectedReason;
  String _customReason = '';
  bool _isLoading = false;

  final List<String> _predefinedReasons = [
    'Zone obsolète - Le danger n\'existe plus',
    'Fausse alerte - Aucun danger réel',
    'Localisation incorrecte',
    'Contenu inapproprié',
    'Spam ou signalement répétitif',
    'Autre raison',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.report_problem,
            color: AppColors.alert,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Signaler un problème',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zone: ${widget.zoneTitle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pourquoi signalez-vous cette zone ?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_predefinedReasons.length, (index) {
              final reason = _predefinedReasons[index];
              return RadioListTile<String>(
                title: Text(
                  reason,
                  style: const TextStyle(fontSize: 14),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                    if (value != 'Autre raison') {
                      _customReason = '';
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            if (_selectedReason == 'Autre raison') ...[
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Précisez la raison',
                  hintText: 'Décrivez le problème...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _customReason = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_canSubmit() ? null : _submitReport,
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
              : const Text('Signaler'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Autre raison') {
      return _customReason.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _submitReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reason = _selectedReason == 'Autre raison' 
          ? _customReason.trim()
          : _selectedReason!;
      
      await widget.onReport(reason);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé avec succès'),
            backgroundColor: Colors.orange,
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
            content: Text('Erreur lors du signalement: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }
}