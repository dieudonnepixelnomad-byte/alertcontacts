import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

import '../../../core/services/analytics_service.dart';
import '../../../theme/colors.dart';
import '../providers/alert_provider.dart';
import 'alert_location_picker_page.dart';

class AlertCreationFlow extends StatefulWidget {
  const AlertCreationFlow({super.key});

  @override
  State<AlertCreationFlow> createState() => _AlertCreationFlowState();
}

class _AlertCreationFlowState extends State<AlertCreationFlow> {
  int _step = 0;
  String _gravity = 'low';
  String _type = 'other';
  final _descController = TextEditingController();
  bool _isAnonymous = true;
  bool _contactsOnly = false;
  bool _submitting = false;

  gmaps.LatLng? _pickedLocation;
  String _pickedAddress = 'Position actuelle';
  bool _loadingLocation = false;

  static const _gravities = [
    ('low', AppColors.gravityLow, '🟡', 'Faible', '30 min · 200m'),
    ('medium', AppColors.gravityMid, '🟠', 'Moyen', '1h · 500m'),
    ('high', AppColors.gravityHigh, '🔴', 'Élevé', '2h · 1km'),
  ];

  static const _types = [
    ('accident', Icons.car_crash_outlined, 'Accident'),
    ('suspect', Icons.person_search_outlined, 'Suspect'),
    ('fire', Icons.local_fire_department_outlined, 'Incendie'),
    ('aggression', Icons.warning_amber_outlined, 'Agression'),
    ('suspicious_package', Icons.inventory_2_outlined, 'Colis suspect'),
    ('other', Icons.report_outlined, 'Autre'),
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Color get _ctaColor => switch (_gravity) {
    'medium' => AppColors.gravityMid,
    'high' => AppColors.gravityHigh,
    _ => AppColors.gravityLow,
  };

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
            'Niveau de gravité',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          ...(_gravities.map((g) {
            final (id, color, emoji, label, meta) = g;
            final selected = _gravity == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _gravity = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : AppColors.gray200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected ? color : AppColors.gray900,
                              ),
                            ),
                            Text(
                              meta,
                              style: tt.labelMedium?.copyWith(
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            );
          })),
          const SizedBox(height: 16),
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
            children: _types.map((t) {
              final (id, iconData, label) = t;
              final selected = _type == id;
              return GestureDetector(
                onTap: () => setState(() => _type = id),
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
                        iconData,
                        size: 18,
                        color: selected ? AppColors.primary : AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
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
          const SizedBox(height: 16),
          Text(
            'Description (optionnel)',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Décris brièvement la situation…',
              filled: true,
              fillColor: AppColors.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle: const TextStyle(
                color: AppColors.gray400,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ToggleTile(
            label: 'Signalement anonyme',
            subtitle: 'Ton nom ne sera pas visible',
            value: _isAnonymous,
            onChanged: (v) => setState(() => _isAnonymous = v),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            label: 'Visible uniquement par mes proches',
            subtitle: 'Signalement privé',
            value: _contactsOnly,
            onChanged: (v) => setState(() => _contactsOnly = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _ctaColor,
                disabledBackgroundColor: AppColors.gray200,
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
    log('_fetchCurrentLocation: début');
    setState(() => _loadingLocation = true);
    try {
      // Vérif permission avant d'appeler getCurrentPosition
      LocationPermission perm = await Geolocator.checkPermission();
      log('_fetchCurrentLocation: permission=$perm');
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        log('_fetchCurrentLocation: permission après demande=$perm');
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        log('_fetchCurrentLocation: permission refusée → fallback Paris');
        if (mounted) {
          setState(() {
            _pickedAddress = 'Position non disponible — appuie pour choisir';
          });
        }
        return;
      }

      // Timeout 10s pour éviter le hang infini
      log('_fetchCurrentLocation: appel getCurrentPosition...');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      log('_fetchCurrentLocation: position obtenue lat=${pos.latitude} lng=${pos.longitude}');

      if (!mounted) return;
      setState(() {
        _pickedLocation = gmaps.LatLng(pos.latitude, pos.longitude);
        _pickedAddress = 'Chargement adresse…';
      });

      // Reverse geocoding
      log('_fetchCurrentLocation: reverse geocoding...');
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 8));
      log('_fetchCurrentLocation: placemarks=${placemarks.length}');

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        log('_fetchCurrentLocation: placemark street=${p.street} locality=${p.locality}');
        final parts = [
          if ((p.street ?? '').isNotEmpty) p.street,
          if ((p.locality ?? '').isNotEmpty) p.locality,
          if ((p.postalCode ?? '').isNotEmpty) p.postalCode,
        ];
        setState(() {
          _pickedAddress =
              parts.isNotEmpty ? parts.join(', ') : 'Position actuelle';
        });
      } else {
        setState(() {
          _pickedAddress =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e, st) {
      log('_fetchCurrentLocation: erreur=$e\n$st');
      if (mounted) {
        setState(() {
          _pickedAddress = 'Erreur GPS — appuie pour choisir manuellement';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
      log('_fetchCurrentLocation: fin, loadingLocation=false');
    }
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final initial = _pickedLocation ?? const gmaps.LatLng(48.8566, 2.3522);
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
      });
    }
  }

  Future<void> _submit() async {
    final pos = _pickedLocation;
    log('AlertCreationFlow._submit: pos=$pos gravity=$_gravity type=$_type');
    if (pos == null) {
      log('AlertCreationFlow._submit: position null → abandon');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position non disponible — réessaie'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'gravity': _gravity,
        'type': _type,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'is_anonymous': _isAnonymous,
        'visibility': _contactsOnly ? 'contacts_only' : 'public',
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
      };
      log('AlertCreationFlow._submit: appel createAlert payload=$payload');
      await context.read<AlertProvider>().createAlert(payload);
      AnalyticsService().logCommunityAlertCreated(gravity: _gravity, type: _type);
      log('AlertCreationFlow._submit: succès');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerte signalée — merci pour la communauté'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      log('AlertCreationFlow._submit: erreur=$e');
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: tt.labelMedium?.copyWith(color: AppColors.gray400),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
