import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_notifier.dart';

import '../services/share_service.dart';
import '../../router/app_router.dart';

class NavbarDrawer extends StatelessWidget {
  const NavbarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildAccountSection(context),
                const Divider(),
                _buildAppSection(context),
                const Divider(),
                _buildSupportSection(context),
                const Divider(),
                _buildLogoutSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, child) {
        final user = authNotifier.user;
        return DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF006970), Color(0xFF004D54)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : user?.email.isNotEmpty == true
                          ? user!.email[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true
                              ? user!.name
                              : 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email.isNotEmpty == true)
                          Text(
                            user!.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Utilisateur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Mon compte',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.person_outline,
          title: 'Profil',
          subtitle: 'Gérer mes informations',
          onTap: () {
            Navigator.pop(context);
            context.push('/profile');
          },
        ),
      ],
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Application',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.settings_outlined,
          title: 'Paramètres',
          subtitle: 'Configuration et préférences',
          onTap: () {
            Navigator.pop(context);
            context.push('/settings');
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.info_outline,
          title: 'À propos',
          subtitle: 'Informations sur l\'application',
          onTap: () {
            debugPrint('Goto About Page');
            Navigator.pop(context);
            context.push('/about');
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Support',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.feedback_outlined,
          title: 'Avis & Suggestions',
          subtitle: 'Partagez votre expérience',
          onTap: () {
            Navigator.pop(context);
            context.go('/feedback');
          },
        ),
        _buildDrawerItem(
          context,
          icon: Icons.share_outlined,
          title: 'Partager l\'application',
          subtitle: 'Recommandez AlertContact',
          onTap: () {
            Navigator.pop(context);
            _shareApp(context);
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildDrawerItem(
        context,
        icon: Icons.logout,
        title: 'Se déconnecter',
        subtitle: null,
        textColor: Colors.red,
        iconColor: Colors.red,
        onTap: () => _showLogoutConfirmation(context),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pop(); // Fermer le drawer

                // Effectuer la déconnexion
                // Le routeur gèrera automatiquement la redirection vers /auth
                // quand l'état d'authentification changera vers unauthenticated
                await context
                    .read<AuthNotifier>()
                    .signOut()
                    .then((_) {
                      if (kDebugMode) {
                        print('Utilisateur déconnecté avec succès');
                      }
                      // Pas de navigation manuelle - le routeur gère automatiquement
                      // la redirection basée sur le changement d'état d'authentification
                    })
                    .onError((error, stackTrace) {
                      if (kDebugMode) {
                        print('Erreur lors de la déconnexion: $error');
                      }
                    });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp(BuildContext context) {
    ShareService.shareApp(
      context: context,
      shareContext: ShareContext.fromSettings,
    );
  }
}
