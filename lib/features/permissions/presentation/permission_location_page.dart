import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/permission_scaffold.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';

class PermissionLocationPage extends StatefulWidget {
  const PermissionLocationPage({super.key});

  @override
  State<PermissionLocationPage> createState() => _PermissionLocationPageState();
}

class _PermissionLocationPageState extends State<PermissionLocationPage> {
  bool _isLoading = false;

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await PermissionsService.requestLocationPermission();
      
      if (granted) {
        // Permission accordée, vérifier si on doit aller aux notifications ou à l'app
        await _navigateNext();
      } else {
        // Permission refusée, afficher un message et permettre de continuer
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de géolocalisation refusée. Vous pouvez l\'activer plus tard dans les paramètres.'),
              duration: Duration(seconds: 3),
            ),
          );
          await _navigateNext();
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

  Future<void> _navigateNext() async {
    // Toujours aller à la page de permission de notifications
    // pour suivre le flux séquentiel : géolocalisation → notifications → arrière-plan
    if (mounted) {
      context.go(AppRoutes.permissionNotification);
    }
  }

  Future<void> _skipPermission() async {
    // Continuer sans accorder la permission
    await _navigateNext();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionScaffold(
      icon: Icons.location_on,
      title: 'Autoriser la géolocalisation',
      bullets: const [
        'Détecter votre position en temps réel',
        'Vous alerter des zones de danger proches',
        'Notifier vos proches de votre sécurité',
      ],
      primaryLabel: _isLoading ? 'Chargement...' : 'Autoriser',
      onPrimary: _isLoading ? () {} : _requestLocationPermission,
      secondaryLabel: 'Plus tard',
      onSecondary: _isLoading ? () {} : _skipPermission,
      helpText: 'Vous pouvez modifier ce choix dans les paramètres.',
    );
  }
}
