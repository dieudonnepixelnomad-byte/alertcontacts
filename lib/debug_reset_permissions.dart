import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script de debug pour réinitialiser l'état des permissions
/// Utiliser ce script pour tester le flux de permissions depuis le début
class DebugResetPermissions {
  static Future<void> resetAllPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Supprimer toutes les clés liées aux permissions
    await prefs.remove('location_permission_granted');
    await prefs.remove('notification_permission_granted');
    await prefs.remove('permissions_setup_complete');
    
    print('🔄 État des permissions réinitialisé');
    print('📍 Permission géolocalisation: supprimée');
    print('🔔 Permission notifications: supprimée');
    print('✅ Setup permissions: supprimé');
  }
  
  static Future<void> showCurrentPermissionsState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final locationGranted = prefs.getBool('location_permission_granted') ?? false;
    final notificationGranted = prefs.getBool('notification_permission_granted') ?? false;
    final setupComplete = prefs.getBool('permissions_setup_complete') ?? false;
    
    print('📊 État actuel des permissions:');
    print('📍 Géolocalisation: $locationGranted');
    print('🔔 Notifications: $notificationGranted');
    print('✅ Setup complet: $setupComplete');
  }
}

/// Widget de debug à ajouter temporairement dans l'app pour tester
class DebugPermissionsWidget extends StatelessWidget {
  const DebugPermissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Permissions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await DebugResetPermissions.showCurrentPermissionsState();
              },
              child: const Text('Afficher état actuel'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await DebugResetPermissions.resetAllPermissions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permissions réinitialisées')),
                );
              },
              child: const Text('Réinitialiser permissions'),
            ),
          ],
        ),
      ),
    );
  }
}