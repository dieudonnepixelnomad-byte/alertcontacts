import 'package:flutter/material.dart';
import '../../../../core/models/danger_zone.dart';
import '../../../../theme/colors.dart';

class ConfirmDangerDialog extends StatefulWidget {
  final DangerZone zone;
  final Function() onConfirm;

  const ConfirmDangerDialog({
    super.key,
    required this.zone,
    required this.onConfirm,
  });

  @override
  State<ConfirmDangerDialog> createState() => _ConfirmDangerDialogState();
}

class _ConfirmDangerDialogState extends State<ConfirmDangerDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.safe,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Confirmer cette zone',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSeverityColor(widget.zone.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getSeverityColor(widget.zone.severity).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getSeverityIcon(widget.zone.severity),
                      color: _getSeverityColor(widget.zone.severity),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.zone.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gravité: ${_getSeverityLabel(widget.zone.severity)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (widget.zone.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.zone.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.zone.confirmations} confirmations',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'En confirmant cette zone, vous aidez la communauté à identifier les zones dangereuses réelles.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vous ne pouvez confirmer qu\'une seule fois par zone.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmZone,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safe,
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
              : const Text('Confirmer'),
        ),
      ],
    );
  }

  Future<void> _confirmZone() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zone confirmée avec succès'),
            backgroundColor: Colors.green,
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
            content: Text('Erreur lors de la confirmation: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  Color _getSeverityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return Colors.orange;
      case DangerSeverity.med:
        return Colors.deepOrange;
      case DangerSeverity.high:
        return AppColors.alert;
    }
  }

  IconData _getSeverityIcon(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return Icons.warning_amber;
      case DangerSeverity.med:
        return Icons.warning;
      case DangerSeverity.high:
        return Icons.dangerous;
    }
  }

  String _getSeverityLabel(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'Faible';
      case DangerSeverity.med:
        return 'Modérée';
      case DangerSeverity.high:
        return 'Élevée';
    }
  }

}