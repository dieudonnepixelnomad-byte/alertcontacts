import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide d\'utilisation'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/app-shell');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            _buildIntroSection(context),
            const SizedBox(height: 24),

            // Guide de démarrage
            _buildQuickStartSection(context),
            const SizedBox(height: 24),

            // Fonctionnalités principales
            _buildFeaturesSection(context),
            const SizedBox(height: 24),

            // Conseils de sécurité
            _buildSecurityTipsSection(context),
            const SizedBox(height: 24),

            // FAQ
            _buildFAQSection(context),
            const SizedBox(height: 24),

            // Contact et support
            _buildSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bienvenue dans AlertContacts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'AlertContacts est votre application de sécurité personnelle qui vous permet de protéger et rassurer vos proches. '
              'Créez des zones de sécurité, signalez des dangers et restez connecté avec votre famille.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: AppColors.teal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Guide de démarrage rapide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              context,
              '1',
              'Créer votre première zone de sécurité',
              'Allez à la page d\'accueil et appuyez sur le bouton vert avec l\'icone de bouclier pour créer une zone autour de votre domicile, école ou lieu de travail.',
              Icons.shield,
            ),
            const SizedBox(height: 12),
            _buildStepItem(
              context,
              '2',
              'Ajouter un proche',
              'Dans l\'onglet "Proches", appuyez sur le bouton "Inviter" pour inviter un membre de votre famille ou un ami à partager sa position.',
              Icons.person_add,
            ),
            const SizedBox(height: 12),
            _buildStepItem(
              context,
              '3',
              'Configurer les notifications',
              'Activez les notifications pour être alerté quand vos proches entrent ou sortent des zones de sécurité.',
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Fonctionnalités principales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.shield,
              'Zones de sécurité',
              'Créez des zones circulaires autour des lieux importants. Recevez des notifications quand vos proches y entrent ou en sortent.',
            ),
            _buildFeatureItem(
              context,
              Icons.warning,
              'Zones de danger',
              'Signalez des zones dangereuses pour alerter la communauté. Confirmez ou infirmez les signalements d\'autres utilisateurs.',
            ),
            _buildFeatureItem(
              context,
              Icons.group,
              'Gestion des proches',
              'Invitez vos proches à partager leur position. Gérez les permissions et le niveau de partage pour chaque contact.',
            ),
            _buildFeatureItem(
              context,
              Icons.map,
              'Carte interactive',
              'Visualisez toutes les zones et positions en temps réel sur une carte intuitive avec filtres et détails.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTipsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: AppColors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Conseils de sécurité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              context,
              '🔒',
              'Respectez la vie privée',
              'Ne partagez votre position qu\'avec des personnes de confiance. Vous pouvez désactiver le partage à tout moment.',
            ),
            _buildTipItem(
              context,
              '⚡',
              'Optimisez la batterie',
              'L\'application utilise une géolocalisation intelligente pour préserver votre batterie tout en restant précise.',
            ),
            _buildTipItem(
              context,
              '🔄',
              'Ne fermez pas completement l\'application',
              'Fermez l\'application en utilisant le bouton "Retour" plutôt que "Arrêter". Cela permet de maintenir la géolocalisation en arrière-plan.',
            ),
            _buildTipItem(
              context,
              '📱',
              'Gardez l\'app à jour',
              'Mettez régulièrement à jour l\'application pour bénéficier des dernières améliorations de sécurité.',
            ),
            _buildTipItem(
              context,
              '🚨',
              'Signalements responsables',
              'Ne signalez que des dangers réels et récents. Les faux signalements peuvent être sanctionnés.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    String emoji,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Questions fréquentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              'Comment inviter un proche ?',
              'Allez dans l\'onglet "Proches", appuyez sur le bouton "Inviter", puis Generer le lien d\'invitation et Partagez le lien généré',
            ),
            _buildFAQItem(
              context,
              'Pourquoi je ne reçois pas de notifications ?',
              'Vérifiez que les notifications sont activées dans les paramètres de votre téléphone et dans l\'application.',
            ),
            _buildFAQItem(
              context,
              'Comment supprimer une zone ?',
              'Appuyez longuement sur la zone dans la liste ou sur la carte, puis sélectionnez "Supprimer".',
            ),
            _buildFAQItem(
              context,
              'L\'app consomme-t-elle beaucoup de batterie ?',
              'Non, AlertContact utilise une géolocalisation optimisée qui préserve votre batterie.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.support_agent,
                  color: AppColors.teal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Besoin d\'aide ?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Notre équipe est là pour vous aider. N\'hésitez pas à nous contacter si vous avez des questions ou rencontrez des problèmes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/feedback');
                    },
                    icon: const Icon(Icons.feedback),
                    label: const Text('Envoyer un feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
