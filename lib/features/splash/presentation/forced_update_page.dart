import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForcedUpdatePage extends StatelessWidget {
  final String storeUrl;

  const ForcedUpdatePage({super.key, required this.storeUrl});

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Gérer l'erreur si l'URL ne peut pas être ouverte
      print('Impossible d\'ouvrir l\'URL: $storeUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Mise à jour requise',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Une nouvelle version de l\'application est disponible. Pour continuer, veuillez installer la mise à jour.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _launchStore,
                child: const Text('Mettre à jour maintenant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}