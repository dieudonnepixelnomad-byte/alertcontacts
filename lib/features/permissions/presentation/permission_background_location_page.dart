import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/widgets/permission_scaffold.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';

class PermissionBackgroundLocationPage extends StatefulWidget {
  const PermissionBackgroundLocationPage({super.key});

  @override
  State<PermissionBackgroundLocationPage> createState() => _PermissionBackgroundLocationPageState();
}

class _PermissionBackgroundLocationPageState extends State<PermissionBackgroundLocationPage> {
  bool _isLoading = false;

  Future<void> _requestBackgroundLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Demander la permission de géolocalisation en arrière-plan
      final status = await Permission.locationAlways.request();
      
      if (status.isGranted) {
        // Permission accordée, continuer vers l'app
        await _completePermissionsSetup();
      } else {
        // Permission refusée, afficher un message et permettre de continuer
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de géolocalisation en arrière-plan refusée. Vous pouvez l\'activer plus tard dans les paramètres.'),
              duration: Duration(seconds: 3),
            ),
          );
          await _completePermissionsSetup();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la demande de permission.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completePermissionsSetup() async {
    // Marquer la configuration des permissions comme terminée
    await PermissionsService.markPermissionsSetupComplete();
    
    // Naviguer vers l'authentification
    if (mounted) {
      context.go(AppRoutes.auth);
    }
  }

  Future<void> _skipPermission() async {
    // Continuer sans accorder la permission
    await _completePermissionsSetup();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionScaffold(
      icon: Icons.location_on,
      title: 'Géolocalisation en arrière-plan',
      bullets: const [
        'Vous protéger même quand l\'app est fermée',
        'Détecter les zones de danger en permanence',
        'Surveiller vos zones de sécurité 24h/24',
        'Alerter vos proches en cas de besoin',
      ],
      primaryLabel: _isLoading ? 'Chargement...' : 'Autoriser',
      onPrimary: _isLoading ? () {} : _requestBackgroundLocationPermission,
      secondaryLabel: 'Plus tard',
      onSecondary: _isLoading ? () {} : _skipPermission,
      helpText: 'Cette permission améliore votre sécurité mais peut consommer plus de batterie. Vous pouvez la modifier dans les paramètres.',
    );
  }
}