import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/user.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/profile_provider.dart';
import '../../../router/app_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthNotifier>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: const Color(0xFF006970),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Consumer2<AuthNotifier, ProfileProvider>(
        builder: (context, authNotifier, profileProvider, child) {
          final user = authNotifier.user;

          if (user == null) {
            return const Center(child: Text('Aucun utilisateur connecté'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(user),
                const SizedBox(height: 24),
                _buildPrivacySection(),
                /* const SizedBox(height: 24),
                _buildDataManagementSection(), */
                const SizedBox(height: 24),
                _buildDangerZone(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF006970),
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        user.emailVerified ? Icons.verified : Icons.warning,
                        size: 16,
                        color: user.emailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.emailVerified
                            ? 'Email vérifié'
                            : 'Email non vérifié',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.emailVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    enabled: false, // L'email ne peut pas être modifié
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      helperText: 'L\'email ne peut pas être modifié',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user.createdAt != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Membre depuis'),
                      subtitle: Text(
                        '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _loadUserData();
                        setState(() => _isEditing = false);
                      },
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006970),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sauvegarder'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidentialité et données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Politique de confidentialité'),
              subtitle: const Text(
                'Consultez notre politique de confidentialité',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showPrivacyPolicy(),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Consentements'),
              subtitle: const Text('Gérez vos consentements de données'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showConsentManagement(),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Données de localisation'),
              subtitle: const Text('Gérez le partage de votre position'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLocationDataManagement(),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des données (RGPD)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Télécharger mes données'),
              subtitle: const Text('Exportez toutes vos données personnelles'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _exportUserData(),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rectifier mes données'),
              subtitle: const Text('Corrigez vos informations personnelles'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => setState(() => _isEditing = true),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red[700]),
              title: Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red[700]),
              ),
              subtitle: const Text(
                'Cette action est irréversible. Toutes vos données seront supprimées.',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDeleteAccountDialog(),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.updateProfile(name: _nameController.text.trim());

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() async {
    final Uri url = Uri.parse('https://mobile.alertcontacts.net/privacy');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showConsentManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestion des consentements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gérez vos consentements pour le traitement de vos données :',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Localisation'),
              subtitle: const Text('Partage de position avec vos proches'),
              value: true,
              onChanged: null, // Requis pour le fonctionnement de l'app
            ),
            CheckboxListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Alertes de sécurité'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Amélioration du service'),
              subtitle: const Text('Données d\'usage anonymisées'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showLocationDataManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Données de localisation'),
        content: const Text(
          'Vos données de localisation sont utilisées uniquement pour :\n\n'
          '• Vous alerter des zones de danger\n'
          '• Informer vos proches de votre sécurité\n'
          '• Créer des zones de sécurité personnalisées\n\n'
          'Vous pouvez désactiver le partage de localisation dans les paramètres, '
          'mais certaines fonctionnalités ne seront plus disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _exportUserData() async {
    try {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.exportUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export des données initié. Vous recevrez un email avec vos données.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDataProcessingLimitation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limitation du traitement'),
        content: const Text(
          'Vous pouvez demander la limitation du traitement de vos données personnelles.\n\n'
          'Cela signifie que vos données seront conservées mais ne seront plus traitées, '
          'sauf pour certaines exceptions légales.\n\n'
          'Cette action peut affecter le fonctionnement de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implémenter la limitation du traitement
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Demander la limitation'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ?\n\n'
          'Cette action est irréversible et entraînera :\n'
          '• La suppression de toutes vos données\n'
          '• La suppression de vos zones de sécurité\n'
          '• La déconnexion de tous vos proches\n'
          '• La perte de votre abonnement Premium\n\n'
          'Tapez "SUPPRIMER" pour confirmer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeleteAccount(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final confirmController = TextEditingController();
    final rootContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tapez "SUPPRIMER" pour confirmer la suppression de votre compte :',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'SUPPRIMER',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text == 'SUPPRIMER') {
                try {
                  final profileProvider = rootContext.read<ProfileProvider>();
                  final authNotifier = rootContext.read<AuthNotifier>();

                  // Supprimer le compte
                  await profileProvider.deleteAccount();

                  if (mounted) {
                    Navigator.pop(dialogContext); // Fermer le dialog
                    Navigator.pop(dialogContext); // Fermer le dialog précédent

                    // Déclencher la déconnexion pour mettre à jour l'état d'authentification
                    await authNotifier.signOut();

                    // Forcer la navigation vers la page d'authentification
                    rootContext.go(AppRoutes.auth);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez taper "SUPPRIMER" pour confirmer'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }
}
