// lib/features/about/presentation/about_page.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(String url) async {
    log('Tentative de lancement de l\'URL: $url');
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: const Color(0xFF006970),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo et nom de l'app
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006970),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/images/splash_logo_blanc.jpg'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AlertContact',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006970),
                    ),
                  ),
                  if (_packageInfo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Description
            _buildSection(
              context,
              'Description',
              'AlertContact est une application de sécurité personnelle qui permet de protéger et rassurer vos proches. '
                  'Créez des zones de sécurité, partagez votre localisation avec vos proches et recevez des alertes en temps réel.',
            ),

            const SizedBox(height: 24),

            // Fonctionnalités principales
            _buildSection(
              context,
              'Fonctionnalités principales',
              null,
              children: [
                _buildFeatureItem('🛡️', 'Zones de sécurité personnalisées'),
                _buildFeatureItem('⚠️', 'Alertes de zones dangereuses'),
                _buildFeatureItem(
                  '👥',
                  'Partage de localisation avec vos proches',
                ),
                _buildFeatureItem('🔔', 'Notifications en temps réel'),
                _buildFeatureItem('🔒', 'Respect de votre vie privée'),
              ],
            ),

            const SizedBox(height: 24),

            // Informations légales
            _buildSection(
              context,
              'Informations légales',
              null,
              children: [
                _buildLegalItem(
                  context,
                  'Politique de confidentialité',
                  'Consultez notre politique de confidentialité',
                  () => _launchUrl('https://mobile.alertcontacts.net/privacy'),
                ),
                _buildLegalItem(
                  context,
                  'Conditions d\'utilisation',
                  'Consultez nos conditions d\'utilisation',
                  () => _launchUrl('https://mobile.alertcontacts.net/terms'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact et support
            _buildSection(
              context,
              'Contact et support',
              null,
              children: [
                _buildContactItem(
                  context,
                  Icons.email,
                  'Support technique',
                  'support@alertcontacts.net',
                  () => _launchUrl('mailto:support@alertcontacts.net'),
                ),
                _buildContactItem(
                  context,
                  Icons.language,
                  'Site web',
                  'www.alertcontacts.net',
                  () => _launchUrl('https://alertcontacts.net'),
                ),
                _buildContactItem(
                  context,
                  Icons.star,
                  'Évaluer l\'application',
                  'Donnez votre avis sur les stores',
                  () => _launchUrl(
                    'https://play.google.com/store/apps/details?id=com.alertcontacts.alertcontacts',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Copyright
            Center(
              child: Text(
                '© 2024 AlertContact. Tous droits réservés.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String? description, {
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006970),
          ),
        ),
        const SizedBox(height: 12),
        if (description != null) ...[
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description, color: Color(0xFF006970)),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF006970)),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
