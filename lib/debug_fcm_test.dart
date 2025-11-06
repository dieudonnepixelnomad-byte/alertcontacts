import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertcontacts/features/auth/providers/auth_notifier.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';

/// Widget de test pour déclencher manuellement la connexion et voir les logs FCM
class FCMTestWidget extends StatelessWidget {
  const FCMTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test FCM'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                log('🧪 TEST: Déconnexion forcée...');
                final authNotifier = context.read<AuthNotifier>();
                await authNotifier.signOut();
              },
              child: const Text('Se déconnecter'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                log('🧪 TEST: Connexion silencieuse forcée...');
                final authNotifier = context.read<AuthNotifier>();
                await authNotifier.silentSignIn();
              },
              child: const Text('Connexion silencieuse'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                log('🧪 TEST: Vérification bearerToken...');
                final prefsService = PrefsService();
                final bearerToken = await prefsService.getBearerToken();
                if (bearerToken != null) {
                  log('✅ TEST: bearerToken trouvé: ${bearerToken.substring(0, 10)}...');
                } else {
                  log('❌ TEST: bearerToken null');
                }
              },
              child: const Text('Vérifier bearerToken'),
            ),
          ],
        ),
      ),
    );
  }
}