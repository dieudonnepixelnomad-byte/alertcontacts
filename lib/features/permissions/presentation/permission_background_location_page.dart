import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/permissions_service.dart';
import '../../../router/app_router.dart';

class PermissionBackgroundLocationPage extends StatefulWidget {
  /// isModal: true → pop(bool granted) au lieu de naviguer vers /auth.
  /// Utiliser Navigator.push<bool> pour récupérer le résultat.
  final bool isModal;
  const PermissionBackgroundLocationPage({super.key, this.isModal = false});

  @override
  State<PermissionBackgroundLocationPage> createState() => _PermissionBackgroundLocationPageState();
}

class _PermissionBackgroundLocationPageState extends State<PermissionBackgroundLocationPage> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    try {
      final status = await Permission.locationAlways.request();
      if (!mounted) return;
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission refusée. Activez-la dans Paramètres > Applications > AlertContacts.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await _complete(status.isGranted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la demande de permission.'), duration: Duration(seconds: 2)),
        );
        await _complete(false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _complete(bool granted) async {
    if (widget.isModal) {
      if (mounted) Navigator.of(context).pop(granted);
      return;
    }
    await PermissionsService.markPermissionsSetupComplete();
    if (mounted) context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1F5EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, size: 40, color: Color(0xFF1E6868)),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Accès à votre position en arrière-plan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
              ),

              const SizedBox(height: 16),

              const Text(
                'AlertContacts collecte votre position géographique même lorsque l\'application est fermée ou inutilisée.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 20),

              const Text(
                'Cette donnée est utilisée pour :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),

              const SizedBox(height: 10),

              const _BulletItem('Détecter votre entrée et sortie de vos zones de sécurité (ex : domicile, école)'),
              const _BulletItem('Notifier vos proches lorsque vous arrivez ou quittez une zone'),
              const _BulletItem('Vous alerter en cas de danger signalé près de vous'),
              const _BulletItem('Assurer votre protection en permanence, même app fermée'),

              const SizedBox(height: 20),

              Text(
                'Votre position est partagée uniquement avec vos proches que vous avez acceptés. Elle n\'est jamais vendue ni transmise à des tiers.',
                style: TextStyle(fontSize: 13, height: 1.5, color: cs.onSurface.withValues(alpha: 0.65)),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6868),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Autoriser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : () => _complete(false),
                  child: Text('Plus tard', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
