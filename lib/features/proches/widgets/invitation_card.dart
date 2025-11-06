import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/share_service.dart';

class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvitationCard({
    super.key,
    required this.invitation,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône de statut
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invitation.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(invitation.status),
                      color: _getStatusColor(invitation.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Informations de l'invitation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Invitation',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(invitation.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                invitation.status.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Niveau: ${invitation.defaultShareLevel.displayName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (invitation.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            invitation.message!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy_link',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18),
                            SizedBox(width: 8),
                            Text('Copier le lien'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 8),
                            Text('Partager'),
                          ],
                        ),
                      ),
                      if (invitation.status == InvitationStatus.pending) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations détaillées
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Utilisation
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Utilisations: ${invitation.usedCount}/${invitation.maxUses ?? "∞"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (invitation.requiresPin) ...[
                          Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'PIN requis',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Expiration
                    Row(
                      children: [
                        Icon(
                          invitation.isExpired ? Icons.schedule_outlined : Icons.schedule,
                          size: 16,
                          color: invitation.isExpired ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            invitation.isExpired
                                ? 'Expirée le ${_formatDate(invitation.expiresAt)}'
                                : 'Expire le ${_formatDate(invitation.expiresAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: invitation.isExpired ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (!invitation.isExpired && invitation.canBeUsed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Zones suggérées
                    if (invitation.suggestedZones.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${invitation.suggestedZones.length} zone(s) suggérée(s)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions rapides
              if (invitation.status == InvitationStatus.pending && !invitation.isExpired) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyInvitationLink(context),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF006970),
                          side: const BorderSide(color: Color(0xFF006970)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareInvitation(context),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Partager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006970),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.expired:
        return Colors.red;
      case InvitationStatus.refused:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Icons.schedule;
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.expired:
        return Icons.cancel;
      case InvitationStatus.refused:
        return Icons.block;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.isNegative) {
      final pastDifference = now.difference(date);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays}j';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours}h';
      } else {
        return '${pastDifference.inMinutes}min';
      }
    } else {
      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inMinutes}min';
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'copy_link':
        _copyInvitationLink(context);
        break;
      case 'share':
        _shareInvitation(context);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  void _copyInvitationLink(BuildContext context) {
    final url = invitation.invitationUrl;
    if (url != null) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien d\'invitation copié'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareInvitation(BuildContext context) {
    final url = invitation.invitationUrl;
    if (url != null) {
      ShareService.shareInvitation(
        context: context,
        inviterName: 'Vous', // L'utilisateur actuel est l'inviteur
        invitationLink: url,
      );
    } else {
      // Fallback : copier le lien si pas d'URL
      _copyInvitationLink(context);
    }
  }
}