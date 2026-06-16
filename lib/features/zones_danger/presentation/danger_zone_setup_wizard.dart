import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/models/danger_zone.dart';
import '../../../features/alertes/services/permissions_manager_service.dart';
import '../../../core/models/safe_zone.dart'; // Pour LatLng
import '../../../core/enums/danger_type.dart';
import '../../../core/services/location_service.dart';
import '../../../theme/colors.dart';
import '../providers/danger_zone_notifier.dart';
import 'widgets/danger_zone_info_step.dart';
import 'widgets/danger_zone_location_step.dart';
import 'widgets/danger_zone_details_step.dart';
import 'duplicate_zones_dialog.dart';

class DangerZoneSetupWizard extends StatefulWidget {
  const DangerZoneSetupWizard({super.key});
  @override
  State<DangerZoneSetupWizard> createState() => _DangerZoneSetupWizardState();
}

class _DangerZoneSetupWizardState extends State<DangerZoneSetupWizard> {
  int _step = 0;
  String _title = '';
  String _description = '';
  LatLng _center = const LatLng(
    3.87000,
    11.51500,
  ); // Position par défaut (sera mise à jour)
  double _radius = 50; // Rayon par défaut plus petit pour les dangers
  DangerSeverity _severity = DangerSeverity.med;
  DangerType _dangerType = DangerType.autre;

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
  }

  Future<void> _initializeUserLocation() async {
    try {
      // Demande locationWhenInUse en contexte (signalement de danger)
      final permStatus = await PermissionsManagerService()
          .requestLocationPermission(context);
      if (!permStatus.isGranted) return;

      // Demande locationAlways en contexte — requise pour la détection de zone en arrière-plan
      if (mounted) {
        await PermissionsManagerService().requestLocationAlwaysPermission(context);
      }

      final point = await LocationService().getCurrentPosition();
      if (mounted && point != null) {
        setState(() => _center = LatLng(point.latitude, point.longitude));
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la localisation: $e');
    }
  }

  void _next() => setState(() => _step = (_step + 1).clamp(0, 2));
  void _prev() => setState(() => _step = (_step - 1).clamp(0, 2));

  Future<void> _createDangerZone() async {
    // Utiliser Future.microtask pour s'assurer que l'appel se fait après le build
    Future.microtask(() async {
      final notifier = context.read<DangerZoneNotifier>();

      final dangerZone = DangerZone(
        id: '', // L'ID sera généré par le backend
        title: _title,
        description: _description.isNotEmpty ? _description : null,
        center: _center,
        radiusMeters: _radius,
        severity: _severity,
        dangerType: _dangerType,
        confirmations: 0,
        lastReportAt: DateTime.now(),
      );

      // Créer la zone via le notifier (avec détection de doublons)
      await notifier.createDangerZone(dangerZone);

      if (!mounted) return;

      // Vérifier s'il y a des zones proches
      if (notifier.state.hasNearbyZones &&
          notifier.state.nearbyZones.isNotEmpty) {
        _showNearbyZonesDialog(notifier.state.nearbyZones, dangerZone);
      } else if (notifier.state.status == DangerZoneStatus.created) {
        // Naviguer vers l'écran de succès
        context.go('/zone-danger/create/success');
      } else if (notifier.state.status == DangerZoneStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notifier.state.errorMessage ?? 'Erreur lors de la création',
            ),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    });
  }

  void _showNearbyZonesDialog(
    List<DangerZone> nearbyZones,
    DangerZone proposedZone,
  ) {
    showDialog(
      context: context,
      builder: (context) => DuplicateZonesDialog(
        duplicateZones: nearbyZones,
        proposedZone: proposedZone,
      ),
    ).then((_) {
      // Vérifier le statut après fermeture du dialog
      final notifier = context.read<DangerZoneNotifier>();
      if (notifier.state.status == DangerZoneStatus.created ||
          notifier.state.status == DangerZoneStatus.confirmed) {
        context.go('/zone-danger/create/success');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: _step > 0 ? _prev : () => context.pop(),
        ),
        title: Text(
          'Signaler un danger',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(context),

            // Contenu de l'étape
            Expanded(
              child: _buildStepContent(),
            ),

            // Boutons de navigation
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index < _step;
          final isCurrent = index == _step;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive || isCurrent
                    ? AppColors.alert
                    : cs.onSurface.withOpacity(0.1),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return DangerZoneInfoStep(
          title: _title,
          description: _description,
          severity: _severity,
          dangerType: _dangerType,
          onTitleChanged: (value) => setState(() => _title = value),
          onDescriptionChanged: (value) => setState(() => _description = value),
          onSeverityChanged: (value) => setState(() => _severity = value),
          onDangerTypeChanged: (value) => setState(() => _dangerType = value),
        );
      case 1:
        return DangerZoneLocationStep(
          center: _center,
          radius: _radius,
          onCenterChanged: (value) => setState(() => _center = value),
          onRadiusChanged: (value) => setState(() => _radius = value),
        );
      case 2:
        return DangerZoneDetailsStep(
          title: _title,
          description: _description,
          center: _center!,
          radius: _radius,
          severity: _severity,
          dangerType: _dangerType,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prev,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.onSurface.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 16),
          Expanded(
            child: Consumer<DangerZoneNotifier>(
              builder: (context, notifier, child) {
                final isCreating =
                    notifier.state.status == DangerZoneStatus.creating;

                return ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : (_step < 2 ? _next : _createDangerZone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alert,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: cs.onSurface.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_step < 2 ? 'Suivant' : 'Signaler'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _title.trim().isNotEmpty;
      case 1:
        return true; // La localisation est toujours valide
      case 2:
        return true; // L'étape de révision est toujours valide
      default:
        return false;
    }
  }
}
