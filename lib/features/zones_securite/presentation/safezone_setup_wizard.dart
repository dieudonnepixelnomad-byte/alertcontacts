// lib/features/zones_securite/presentation/safezone_setup_wizard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/models/safe_zone.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/services/native_location_service.dart';
import '../../../core/repositories/safezone_repository.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../theme/colors.dart';
import 'widgets/zone_name_icon_step.dart';
import 'widgets/zone_place_radius_step.dart';
import 'dart:async';

class SafeZoneSetupWizard extends StatefulWidget {
  const SafeZoneSetupWizard({super.key});
  @override
  State<SafeZoneSetupWizard> createState() => _SafeZoneSetupWizardState();
}

class _SafeZoneSetupWizardState extends State<SafeZoneSetupWizard> {
  late final SafeZoneRepository _repo;

  int _step = 0;
  String _name = 'Maison';
  String _iconKey = 'home';
  LatLng _center = const LatLng(3.87000, 11.51500); // Position par défaut (sera mise à jour)
  double _radius = 100;
  String? _address;
  bool _isCreating = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SafeZoneRepository>();
    _initializeUserLocation();
  }

  @override
  void dispose() {
    // Nettoyer les ressources si nécessaire
    super.dispose();
  }

  Future<void> _initializeUserLocation() async {
    try {
      // Vérifier les permissions
      final permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        final requestResult = await Permission.locationWhenInUse.request();
        if (requestResult.isDenied) {
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission.isPermanentlyDenied) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Obtenir la position actuelle via notre service natif
      final nativeLocationService = NativeLocationService();
      
      // Écouter le stream de localisation pour obtenir la position actuelle
      StreamSubscription? locationSubscription;
      locationSubscription = nativeLocationService.locationStream.listen((locationPoint) {
        if (!mounted) return;
        setState(() {
          _center = LatLng(locationPoint.latitude, locationPoint.longitude);
          _isLoadingLocation = false;
        });
        
        // Annuler l'écoute après avoir reçu la première position
        locationSubscription?.cancel();
      });
      
      // Si aucune position n'est reçue dans les 10 secondes, arrêter le chargement
      Timer(const Duration(seconds: 10), () {
        if (_isLoadingLocation) {
          locationSubscription?.cancel();
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la localisation: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _next() => setState(() => _step = (_step + 1).clamp(0, 1));
  void _prev() => setState(() => _step = (_step - 1).clamp(0, 1));

  Future<void> _createZone() async {
    if (_isCreating) return;
    
    setState(() => _isCreating = true);
    
    try {
      final zone = SafeZone(
        id: '', // L'ID sera généré par le backend
        name: _name,
        iconKey: _iconKey,
        center: _center,
        radiusMeters: _radius,
        address: _address,
        memberIds: [], // Pas d'affectation de proches lors de la création
      );

      // Créer la zone via l'API
      final createdZone = await _repo.createSafeZone(zone);
      
      if (!mounted) return;

      // Marquer le setup initial comme terminé
      final prefsService = PrefsService();
      await prefsService.setInitialSetupDone();

      // Naviguer vers l'écran de succès
      context.go(
        '/safezone/setup/success?zoneName=${Uri.encodeComponent(createdZone.name)}&iconKey=${createdZone.iconKey}',
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isCreating = false);
      
      // Gérer les différents types d'erreurs
      String errorMessage = 'Une erreur est survenue lors de la création de la zone.';
      
      if (e is ValidationException) {
        errorMessage = 'Données invalides. Veuillez vérifier vos informations.';
      } else if (e is NetworkException) {
        errorMessage = 'Problème de connexion. Vérifiez votre connexion internet.';
      } else if (e is InvalidCredentialsException) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        // Rediriger vers la page de connexion
        context.go('/auth');
        return;
      }
      
      // Afficher l'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ZoneNameIconStep(
        initialName: _name,
        initialIconKey: _iconKey,
        onChanged: (n, i) {
          _name = n;
          _iconKey = i;
        },
        onNext: _next,
      ),
      ZonePlaceRadiusStep(
        center: _center,
        radius: _radius,
        address: _address,
        onChanged: (center, radius, address) {
          setState(() {
            _center = center;
            _radius = radius;
            _address = address;
          });
        },
        onNext: _createZone, // Créer la zone directement après cette étape
        onPrev: _prev,
        isCreating: _isCreating, // Passer l'état de création
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Créer une zone sécurisée',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prev)
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            height: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LinearProgressIndicator(
              value: (_step + 1) / 2, // Maintenant sur 2 étapes au lieu de 3
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Indicateur d'étape
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Étape ${_step + 1} sur 2', // Maintenant sur 2 étapes au lieu de 3
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: pages[_step],
            ),
          ),
        ],
      ),
    );
  }
}
