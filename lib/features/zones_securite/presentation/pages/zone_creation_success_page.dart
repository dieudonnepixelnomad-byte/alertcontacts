// lib/features/zones_securite/presentation/pages/zone_creation_success_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/prefs_service.dart';
import '../../../../core/services/share_service.dart';

class ZoneCreationSuccessPage extends StatelessWidget {
  final String zoneName;
  final String iconKey;

  const ZoneCreationSuccessPage({
    super.key,
    required this.zoneName,
    required this.iconKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animation de succès
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.teal,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre de succès
                Text(
                  'Zone créée avec succès !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Nom de la zone
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconData(iconKey),
                          color: AppColors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          zoneName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'Votre zone de sécurité est maintenant active.\nVous recevrez des notifications lorsque vos proches entreront ou sortiront de cette zone.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Fonctionnalités disponibles
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Prochaines étapes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        Icons.person_add,
                        'Inviter des proches',
                        'Partagez votre zone avec vos proches',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.notifications,
                        'Configurer les notifications',
                        'Personnalisez vos alertes',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.map,
                        'Voir sur la carte',
                        'Visualisez votre zone sur la carte',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Boutons d'action
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Marquer le setup comme terminé
                          final prefsService = PrefsService();
                          await prefsService.setInitialSetupDone();
                          // Aller à la carte principale
                          if (context.mounted) {
                            context.go('/app-shell');
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Voir sur la carte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ShareService.shareApp(
                            context: context,
                            shareContext: ShareContext.afterSuccessfulZoneCreation,
                            customMessage: 'J\'ai créé une zone de sécurité "$zoneName" avec AlertContact ! Rejoignez-moi pour protéger nos proches ensemble.',
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Inviter des proches'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          side: const BorderSide(color: AppColors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
    return Row(
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
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.gray700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      case 'location_on':
        return Icons.location_on;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.place;
    }
  }
}
