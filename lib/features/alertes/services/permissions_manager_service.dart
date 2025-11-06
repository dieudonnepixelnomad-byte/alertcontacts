import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service de gestion centralisée des permissions
/// Gère toutes les permissions nécessaires pour AlertContact
class PermissionsManagerService {
  static final PermissionsManagerService _instance = PermissionsManagerService._internal();
  factory PermissionsManagerService() => _instance;
  PermissionsManagerService._internal();

  /// Vérifie si toutes les permissions critiques sont accordées
  Future<bool> areAllCriticalPermissionsGranted() async {
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;

    return locationStatus.isGranted && 
           locationAlwaysStatus.isGranted && 
           notificationStatus.isGranted;
  }

  /// Demande toutes les permissions critiques
  Future<Map<Permission, PermissionStatus>> requestAllCriticalPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.notification,
    ];

    return await permissions.request();
  }

  /// Demande la permission de localisation avec explication
  Future<PermissionStatus> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;
    
    if (status.isDenied) {
      // Afficher une explication avant de demander la permission
      final shouldRequest = await _showPermissionDialog(
        context,
        'Permission de localisation',
        'AlertContact a besoin d\'accéder à votre localisation pour vous alerter des zones de danger à proximité.',
        Icons.location_on,
      );

      if (shouldRequest) {
        return await Permission.location.request();
      }
    }

    return status;
  }

  /// Demande la permission de localisation en arrière-plan
  Future<PermissionStatus> requestLocationAlwaysPermission(BuildContext context) async {
    final status = await Permission.locationAlways.status;
    
    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        'Localisation en arrière-plan',
        'Pour vous protéger même quand l\'application est fermée, AlertContact a besoin d\'accéder à votre localisation en permanence.',
        Icons.location_on,
      );

      if (shouldRequest) {
        return await Permission.locationAlways.request();
      }
    }

    return status;
  }

  /// Demande la permission des notifications
  Future<PermissionStatus> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        'Notifications',
        'AlertContact a besoin d\'envoyer des notifications pour vous alerter immédiatement des dangers.',
        Icons.notifications,
      );

      if (shouldRequest) {
        return await Permission.notification.request();
      }
    }

    return status;
  }

  /// Ouvre les paramètres de l'application
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Vérifie le statut d'une permission spécifique
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Affiche un dialogue d'explication pour une permission
  Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: const Color(0xFF006970)),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006970),
                foregroundColor: Colors.white,
              ),
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Affiche un dialogue pour rediriger vers les paramètres
  Future<void> showSettingsDialog(BuildContext context, String permissionName) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission requise'),
          content: Text(
            'La permission "$permissionName" est nécessaire pour le bon fonctionnement d\'AlertContact. '
            'Veuillez l\'activer dans les paramètres de l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006970),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        );
      },
    );
  }

  /// Vérifie et demande les permissions au démarrage de l'application
  Future<bool> initializePermissions(BuildContext context) async {
    try {
      // Vérifier d'abord les permissions actuelles
      final locationStatus = await Permission.location.status;
      final notificationStatus = await Permission.notification.status;

      bool allGranted = true;

      // Demander la permission de localisation si nécessaire
      if (!locationStatus.isGranted) {
        final newStatus = await requestLocationPermission(context);
        if (!newStatus.isGranted) {
          allGranted = false;
        }
      }

      // Demander la permission des notifications si nécessaire
      if (!notificationStatus.isGranted) {
        final newStatus = await requestNotificationPermission(context);
        if (!newStatus.isGranted) {
          allGranted = false;
        }
      }

      // Demander la permission de localisation en arrière-plan après les autres
      final locationAlwaysStatus = await Permission.locationAlways.status;
      if (!locationAlwaysStatus.isGranted && locationStatus.isGranted) {
        await requestLocationAlwaysPermission(context);
      }

      return allGranted;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des permissions: $e');
      return false;
    }
  }
}