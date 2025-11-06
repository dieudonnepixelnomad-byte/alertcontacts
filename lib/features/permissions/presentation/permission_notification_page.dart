import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/permission_scaffold.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';

class PermissionNotificationPage extends StatefulWidget {
  const PermissionNotificationPage({super.key});

  @override
  State<PermissionNotificationPage> createState() => _PermissionNotificationPageState();
}

class _PermissionNotificationPageState extends State<PermissionNotificationPage> {
  bool _isLoading = false;

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await PermissionsService.requestNotificationPermission();
      
      if (granted) {
        // Permission accordée, aller à la permission arrière-plan
        await _navigateToBackgroundLocation();
      } else {
        // Permission refusée, afficher un message et permettre de continuer
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de notification refusée. Vous pouvez l\'activer plus tard dans les paramètres.'),
              duration: Duration(seconds: 3),
            ),
          );
          await _navigateToBackgroundLocation();
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

  Future<void> _navigateToBackgroundLocation() async {
    // Aller à la page de permission de géolocalisation en arrière-plan
    if (mounted) {
      context.go(AppRoutes.permissionBackgroundLocation);
    }
  }

  Future<void> _skipPermission() async {
    // Continuer sans accorder la permission
    await _navigateToBackgroundLocation();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionScaffold(
      icon: Icons.notifications,
      title: 'Autoriser les notifications',
      bullets: const [
        'Recevoir des alertes en temps réel',
        'Être notifié des mouvements de vos proches',
        'Rester informé des zones de danger',
      ],
      primaryLabel: _isLoading ? 'Chargement...' : 'Autoriser',
      onPrimary: _isLoading ? () {} : _requestNotificationPermission,
      secondaryLabel: 'Plus tard',
      onSecondary: _isLoading ? () {} : _skipPermission,
      helpText: 'Vous pouvez modifier ce choix dans les paramètres.',
    );
  }
}
