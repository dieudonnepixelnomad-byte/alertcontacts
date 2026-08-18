import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../../core/enums/incident_type.dart';
import '../../../core/models/incident.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/gps_trace_recorder.dart';
import '../../../theme/colors.dart';
import '../providers/incident_provider.dart';
import 'alert_location_picker_page.dart';

/// Formulaire de signalement — CDC V4.1 §6.6
///
/// Le parcours reste en trois taps. Contrainte absolue du §4.6 : une personne
/// qui signale une agression est en état de stress, elle ne dessinera pas de
/// polygone. Tous les changements V4.1 sont donc invisibles pour elle :
///
///   * la précision du fix et les derniers mètres de trace partent avec le
///     signalement, et le serveur en déduit corridor ou polygone serré ;
///   * le rayon et la durée ne sont plus affichés — ils dépendent du type,
///     plus de la gravité (§4.1) ;
///   * un incident compatible à moins de 150 m propose de confirmer plutôt
///     que de créer un doublon.
class AlertCreationFlow extends StatefulWidget {
  const AlertCreationFlow({super.key});

  @override
  State<AlertCreationFlow> createState() => _AlertCreationFlowState();
}

class _AlertCreationFlowState extends State<AlertCreationFlow> {
  int _step = 0;
  IncidentSeverity _severity = IncidentSeverity.medium;
  IncidentType _type = IncidentType.other;
  final _descController = TextEditingController();
  bool _contactsOnly = false;
  bool _submitting = false;

  gmaps.LatLng? _pickedLocation;
  String _pickedAddress = 'Position actuelle';
  bool _loadingLocation = false;

  /// §4.8 — fourni gratuitement par le SDK, et jeté par le V4.0.
  int? _gpsAccuracyM;
  double? _speedKmh;

  /// La position a-t-elle été déplacée à la main ? Dans ce cas la trace GPS
  /// ne décrit plus le lieu signalé et ne doit pas servir de corridor.
  bool _locationPickedManually = false;

  static const _severities = [
    (IncidentSeverity.low, '🟡'),
    (IncidentSeverity.medium, '🟠'),
    (IncidentSeverity.high, '🔴'),
  ];

  /// Icône par type — §4.9 en compte dix, dont quatre absents du V4.0.
  static const Map<IncidentType, IconData> _typeIcons = {
    IncidentType.accident: Icons.car_crash_outlined,
    IncidentType.fire: Icons.local_fire_department_outlined,
    IncidentType.aggression: Icons.warning_amber_outlined,
    IncidentType.suspect: Icons.person_search_outlined,
    IncidentType.suspiciousPackage: Icons.inventory_2_outlined,
    IncidentType.trafficJam: Icons.traffic_outlined,
    IncidentType.roadworks: Icons.construction_outlined,
    IncidentType.flood: Icons.water_outlined,
    IncidentType.protest: Icons.campaign_outlined,
    IncidentType.other: Icons.report_outlined,
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  /// Le CTA change de couleur selon la gravité. C'est une friction
  /// intentionnelle.
  Color get _ctaColor => _severity.color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_step == 1)
                IconButton(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: AppColors.gray400,
                  padding: EdgeInsets.zero,
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Text(
                  _step == 0 ? 'Type d\'alerte' : 'Détails',
                  style: tt.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.gray400,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _step == 0 ? _buildStep1(tt) : _buildStep2(tt)),
      ],
    );
  }

  Widget _buildStep1(TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Type d\'incident',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: IncidentType.reportable.map((type) {
              final selected = _type == type;

              return GestureDetector(
                onTap: () => setState(() => _type = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _typeIcons[type] ?? Icons.report_outlined,
                        size: 18,
                        color: selected ? AppColors.primary : AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          type.label,
                          style: tt.bodySmall?.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.gray600,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Niveau de gravité',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          // §4.1 — la gravité ne détermine plus que la couleur, la priorité et
          // le tri. Ni durée ni rayon ne sont affichés : ils dépendent du type.
          ..._severities.map((entry) {
            final (severity, emoji) = entry;
            final selected = _severity == severity;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _severity = severity),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? severity.color.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? severity.color : AppColors.gray200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          severity.label,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? severity.color
                                : AppColors.gray900,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          color: severity.color,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                setState(() => _step = 1);
                _fetchCurrentLocation();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _ctaColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Suivant',
                style: tt.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep2(TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Localisation',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openLocationPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  _loadingLocation
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Expanded(
                          child: Text(
                            _pickedAddress,
                            style: tt.bodyMedium?.copyWith(
                              color: AppColors.gray900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Précisions (facultatif)',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Ce que tu as vu, en quelques mots',
              filled: true,
              fillColor: AppColors.gray600,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _ToggleTile(
            label: 'Visible par mes proches seulement',
            subtitle: 'Ton alerte n\'apparaît pas sur la carte publique',
            value: _contactsOnly,
            onChanged: (value) => setState(() => _contactsOnly = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _ctaColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Signaler',
                      style: tt.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          setState(
            () => _pickedAddress =
                'Position non disponible — appuie pour choisir',
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      setState(() {
        _pickedLocation = gmaps.LatLng(pos.latitude, pos.longitude);
        // §4.8 — la précision conditionne le buffer d'évitement et, au-delà de
        // 80 m, interdit à l'incident de modifier des itinéraires.
        _gpsAccuracyM = pos.accuracy.round();
        _speedKmh = pos.speed * 3.6;
        _pickedAddress = 'Chargement adresse…';
      });

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          if ((place.street ?? '').isNotEmpty) place.street,
          if ((place.locality ?? '').isNotEmpty) place.locality,
          if ((place.postalCode ?? '').isNotEmpty) place.postalCode,
        ];

        setState(() {
          _pickedAddress = parts.isNotEmpty
              ? parts.join(', ')
              : 'Position actuelle';
        });
      } else {
        setState(() {
          _pickedAddress =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      log('[AlertCreationFlow] localisation: $e');

      if (mounted) {
        setState(
          () => _pickedAddress = 'Position indisponible — appuie pour choisir',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final initial = _pickedLocation;

    if (initial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position en cours de récupération…')),
      );
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => AlertLocationPickerPage(initialPosition: initial),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _pickedLocation = result.latLng as gmaps.LatLng;
        _pickedAddress = result.address as String;
        // Position choisie à la main : la trace du porteur ne décrit plus le
        // lieu signalé, et la précision du fix n'a plus de sens.
        _locationPickedManually = true;
        _gpsAccuracyM = null;
        _speedKmh = null;
      });
    }
  }

  Future<void> _submit() async {
    final pos = _pickedLocation;

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position non disponible — réessaie'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final provider = context.read<IncidentProvider>();

    // §6.6 — un incident compatible existe déjà ici ? On propose de le
    // confirmer. Un doublon potentiel devient ainsi une confirmation, ce qui
    // renforce la confiance de l'incident au lieu de polluer la carte.
    final duplicate = await provider.checkDuplicate(
      type: _type,
      lat: pos.latitude,
      lng: pos.longitude,
    );

    if (!mounted) return;

    if (duplicate != null && duplicate.found && duplicate.incident != null) {
      final confirmed = await _askConfirmDuplicate(duplicate.incident!);

      if (!mounted) return;

      if (confirmed == null) {
        // L'utilisateur a fermé la modale : on ne signale rien.
        setState(() => _submitting = false);
        return;
      }

      if (confirmed) {
        await provider.confirm(duplicate.incident!.id);

        if (!mounted) return;

        AnalyticsService().logCommunityAlertConfirmed();
        Navigator.pop(context);
        _snack(
          'Merci — ton témoignage renforce cette alerte.',
          AppColors.success,
        );
        return;
      }
    }

    try {
      // §4.6 cas 1 — la trace du porteur devient la géométrie de la voie.
      final trace = _locationPickedManually
          ? null
          : GpsTraceRecorder().currentTrace();

      await provider.submitReport(
        type: _type,
        severity: _severity,
        lat: pos.latitude,
        lng: pos.longitude,
        gpsAccuracyM: _gpsAccuracyM,
        gpsTrace: trace,
        wasMoving: trace != null,
        speedKmh: _speedKmh?.round(),
        comment: _descController.text.trim(),
        contactsOnly: _contactsOnly,
      );

      AnalyticsService().logCommunityAlertCreated(
        gravity: _severity.value,
        type: _type.value,
      );

      if (!mounted) return;

      Navigator.pop(context);
      _snack('Alerte signalée — merci pour la communauté', AppColors.success);
    } catch (e) {
      log('[AlertCreationFlow] submit: $e');

      if (mounted) {
        setState(() => _submitting = false);
        _snack('Envoi impossible pour le moment. Réessaie.', AppColors.danger);
      }
    }
  }

  /// Retourne `true` pour confirmer l'incident existant, `false` pour créer
  /// quand même un nouveau signalement, `null` si la modale est fermée.
  Future<bool?> _askConfirmDuplicate(Incident incident) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Incident déjà signalé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${incident.type.emoji} ${incident.type.label}'),
            const SizedBox(height: 6),
            Text(
              'Un incident similaire est déjà signalé ici. Confirmer ?',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              incident.reportCountLabel,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('C\'est autre chose'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.bodyMedium),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(color: AppColors.gray400),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
