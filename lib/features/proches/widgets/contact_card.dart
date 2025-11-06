import 'package:flutter/material.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/models/invitation.dart';

class ContactCard extends StatelessWidget {
  final ContactRelation relationship;
  final VoidCallback? onTap;
  final Function(ShareLevel)? onUpdateShareLevel;
  final VoidCallback? onDelete;

  const ContactCard({
    super.key,
    required this.relationship,
    this.onTap,
    this.onUpdateShareLevel,
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
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: relationship.contact.avatarUrl != null
                        ? NetworkImage(relationship.contact.avatarUrl!)
                        : null,
                    backgroundColor: const Color(0xFF006970),
                    child: relationship.contact.avatarUrl == null
                        ? Text(
                            relationship.contact.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // Informations du contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relationship.contact.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (relationship.contact.email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            relationship.contact.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Statut
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(relationship.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                relationship.status.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            // Niveau de partage (si accepté)
                            if (relationship.status == RelationStatus.accepted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getShareLevelColor(relationship.shareLevel),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  relationship.shareLevel.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      if (relationship.status == RelationStatus.accepted) ...[
                        const PopupMenuItem(
                          value: 'share_realtime',
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 18),
                              SizedBox(width: 8),
                              Text('Temps réel'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share_alerts',
                          child: Row(
                            children: [
                              Icon(Icons.notifications, size: 18),
                              SizedBox(width: 8),
                              Text('Alertes uniquement'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share_none',
                          child: Row(
                            children: [
                              Icon(Icons.location_off, size: 18),
                              SizedBox(width: 8),
                              Text('Aucun partage'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
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
                  ),
                ],
              ),
              
              // Informations supplémentaires
              if (relationship.status == RelationStatus.accepted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        relationship.canSeeMe ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        color: relationship.canSeeMe ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          relationship.canSeeMe
                              ? 'Peut voir votre position'
                              : 'Ne peut pas voir votre position',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: relationship.canSeeMe ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (relationship.acceptedAt != null) ...[
                        Text(
                          'Depuis ${_formatDate(relationship.acceptedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Message pour les invitations en attente
              if (relationship.status == RelationStatus.pending) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'En attente d\'acceptation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RelationStatus status) {
    switch (status) {
      case RelationStatus.accepted:
        return Colors.green;
      case RelationStatus.pending:
        return Colors.orange;
      case RelationStatus.refused:
        return Colors.red;
    }
  }

  Color _getShareLevelColor(ShareLevel shareLevel) {
    switch (shareLevel) {
      case ShareLevel.realtime:
        return const Color(0xFF006970);
      case ShareLevel.alertOnly:
        return Colors.blue;
      case ShareLevel.none:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share_realtime':
        onUpdateShareLevel?.call(ShareLevel.realtime);
        break;
      case 'share_alerts':
        onUpdateShareLevel?.call(ShareLevel.alertOnly);
        break;
      case 'share_none':
        onUpdateShareLevel?.call(ShareLevel.none);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}