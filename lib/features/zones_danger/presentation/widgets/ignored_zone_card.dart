import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/ignored_danger_zone.dart';
import '../../../../theme/colors.dart';

class IgnoredZoneCard extends StatelessWidget {
  final IgnoredDangerZone ignoredZone;
  final bool isExpired;
  final VoidCallback? onReactivate;
  final VoidCallback? onExtend;

  const IgnoredZoneCard({
    super.key,
    required this.ignoredZone,
    this.isExpired = false,
    this.onReactivate,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final dangerZone = ignoredZone.dangerZone;
    final timeUntilExpiration = ignoredZone.timeUntilExpiration;
    final isNearExpiration = timeUntilExpiration != null && 
        timeUntilExpiration.inDays <= 7 && 
        !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpired 
              ? Colors.grey[300]! 
              : isNearExpiration 
                  ? Colors.orange[300]!
                  : Colors.transparent,
          width: isExpired || isNearExpiration ? 1 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildZoneInfo(context),
            const SizedBox(height: 12),
            _buildTimeInfo(context),
            if (!isExpired) ...[
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isExpired 
                ? Colors.grey[100] 
                : AppColors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isExpired ? Icons.history : Icons.visibility_off,
            color: isExpired ? Colors.grey[600] : AppColors.teal,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ignoredZone.dangerZone?.title ?? 'Zone sans nom',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isExpired ? Colors.grey[600] : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (ignoredZone.dangerZone?.severity != null)
          _buildSeverityBadge(),
      ],
    );
  }

  Widget _buildZoneInfo(BuildContext context) {
    final dangerZone = ignoredZone.dangerZone;
    if (dangerZone == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dangerZone.description?.isNotEmpty == true) ...[
          Text(
            dangerZone.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${dangerZone.center.lat.toStringAsFixed(4)}, ${dangerZone.center.lng.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Ignoré le ${DateFormat('dd/MM/yyyy à HH:mm').format(ignoredZone.ignoredAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isExpired ? Icons.event_busy : Icons.event_available,
                size: 16,
                color: isExpired ? Colors.red[600] : Colors.green[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                isExpired 
                    ? 'Expiré le ${DateFormat('dd/MM/yyyy à HH:mm').format(ignoredZone.expiresAt ?? DateTime.now())}'
                    : 'Expire le ${DateFormat('dd/MM/yyyy à HH:mm').format(ignoredZone.expiresAt ?? DateTime.now())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isExpired ? Colors.red[600] : Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (!isExpired && ignoredZone.timeUntilExpirationText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Temps restant : ${ignoredZone.timeUntilExpirationText}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getTimeRemainingColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReactivate,
            icon: const Icon(Icons.notifications_active, size: 18),
            label: const Text('Réactiver'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onExtend,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Prolonger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge() {
    final severity = ignoredZone.dangerZone?.severity;
    if (severity == null) return const SizedBox.shrink();

    Color badgeColor;
    String severityText;

    switch (severity.name) {
      case 'low':
        badgeColor = Colors.yellow[700]!;
        severityText = 'Faible';
        break;
      case 'med':
        badgeColor = Colors.orange[700]!;
        severityText = 'Moyen';
        break;
      case 'high':
        badgeColor = Colors.red[700]!;
        severityText = 'Élevé';
        break;
      default:
        badgeColor = Colors.grey[600]!;
        severityText = severity.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        severityText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText() {
    if (isExpired) {
      return 'Expiré';
    }
    
    final timeUntilExpiration = ignoredZone.timeUntilExpiration;
    if (timeUntilExpiration != null && timeUntilExpiration.inDays <= 7) {
      return 'Expire bientôt';
    }
    
    return 'Actif';
  }

  Color _getStatusColor() {
    if (isExpired) {
      return Colors.red[600]!;
    }
    
    final timeUntilExpiration = ignoredZone.timeUntilExpiration;
    if (timeUntilExpiration != null && timeUntilExpiration.inDays <= 7) {
      return Colors.orange[600]!;
    }
    
    return Colors.green[600]!;
  }

  Color _getTimeRemainingColor() {
    final timeUntilExpiration = ignoredZone.timeUntilExpiration;
    if (timeUntilExpiration == null) return Colors.grey[600]!;
    
    if (timeUntilExpiration.inDays <= 1) {
      return Colors.red[600]!;
    } else if (timeUntilExpiration.inDays <= 7) {
      return Colors.orange[600]!;
    }
    
    return Colors.green[600]!;
  }
}