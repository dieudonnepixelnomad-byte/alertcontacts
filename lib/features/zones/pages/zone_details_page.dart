import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/zone.dart';

class ZoneDetailsPage extends StatefulWidget {
  final Zone zone;

  const ZoneDetailsPage({
    super.key,
    required this.zone,
  });

  @override
  State<ZoneDetailsPage> createState() => _ZoneDetailsPageState();
}

class _ZoneDetailsPageState extends State<ZoneDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDanger = widget.zone.type == ZoneType.danger;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Détails de la zone',
          style: theme.appBarTheme.titleTextStyle?.copyWith(color: cs.onPrimary),
        ),
        backgroundColor: isDanger ? cs.error : cs.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et nom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDanger
                          ? cs.error.withOpacity(0.1)
                          : cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDanger ? Icons.warning : Icons.shield,
                      color: isDanger ? cs.error : cs.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.zone.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDanger ? cs.error : cs.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDanger ? 'Zone de danger' : 'Zone de sécurité',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        LatLng(widget.zone.center.lat, widget.zone.center.lng),
                    zoom: 15,
                  ),
                  circles: {
                    Circle(
                      circleId: CircleId(widget.zone.id),
                      center:
                          LatLng(widget.zone.center.lat, widget.zone.center.lng),
                      radius: widget.zone.radiusMeters,
                      fillColor: (isDanger ? cs.error : cs.primary)
                          .withOpacity(0.2),
                      strokeColor: (isDanger ? cs.error : cs.primary)
                          .withOpacity(0.8),
                      strokeWidth: 2,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.zone.id),
                      position:
                          LatLng(widget.zone.center.lat, widget.zone.center.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        isDanger ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
                      ),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations générales
            _buildInfoSection(
              theme: theme,
              cs: cs,
              title: 'Informations générales',
              children: [
                _buildInfoRow(
                  theme: theme,
                  cs: cs,
                  icon: Icons.radio_button_unchecked,
                  label: 'Rayon',
                  value: '${widget.zone.radiusMeters.toStringAsFixed(0)} mètres',
                ),
                _buildInfoRow(
                  theme: theme,
                  cs: cs,
                  icon: Icons.location_on,
                  label: 'Coordonnées',
                  value:
                      '${widget.zone.center.lat.toStringAsFixed(6)}, ${widget.zone.center.lng.toStringAsFixed(6)}',
                ),
                if (widget.zone.address?.isNotEmpty == true)
                  _buildInfoRow(
                    theme: theme,
                    cs: cs,
                    icon: Icons.place,
                    label: 'Adresse',
                    value: widget.zone.address!,
                  ),
                _buildInfoRow(
                  theme: theme,
                  cs: cs,
                  icon: Icons.access_time,
                  label: 'Créée le',
                  value:
                      DateFormat('dd/MM/yyyy à HH:mm').format(widget.zone.createdAt),
                ),
                _buildInfoRow(
                  theme: theme,
                  cs: cs,
                  icon: Icons.update,
                  label: 'Modifiée le',
                  value:
                      DateFormat('dd/MM/yyyy à HH:mm').format(widget.zone.updatedAt),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description si disponible
            if (widget.zone.description?.isNotEmpty == true) ...[
              _buildInfoSection(
                theme: theme,
                cs: cs,
                title: 'Description',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.zone.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Informations spécifiques selon le type
            if (isDanger) ...[
              _buildDangerSpecificInfo(theme: theme, cs: cs),
            ] else ...[
              _buildSafeSpecificInfo(theme: theme, cs: cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required ColorScheme cs,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: cs.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSpecificInfo({required ThemeData theme, required ColorScheme cs}) {
    return _buildInfoSection(
      theme: theme,
      cs: cs,
      title: 'Informations de danger',
      children: [
        _buildInfoRow(
          theme: theme,
          cs: cs,
          icon: Icons.priority_high,
          label: 'Niveau de sévérité',
          value: _getSeverityLabel(widget.zone.severity),
        ),
        _buildInfoRow(
          theme: theme,
          cs: cs,
          icon: Icons.verified,
          label: 'Confirmations',
          value: '${widget.zone.confirmations ?? 0} confirmation(s)',
        ),
        if (widget.zone.lastReportAt != null)
          _buildInfoRow(
            theme: theme,
            cs: cs,
            icon: Icons.report,
            label: 'Dernier signalement',
            value: DateFormat('dd/MM/yyyy à HH:mm')
                .format(widget.zone.lastReportAt!),
          ),
      ],
    );
  }

  Widget _buildSafeSpecificInfo({required ThemeData theme, required ColorScheme cs}) {
    return _buildInfoSection(
      theme: theme,
      cs: cs,
      title: 'Informations de sécurité',
      children: [
        if (widget.zone.iconKey?.isNotEmpty == true)
          _buildInfoRow(
            theme: theme,
            cs: cs,
            icon: Icons.category,
            label: 'Catégorie',
            value: _getIconLabel(widget.zone.iconKey!),
          ),
        _buildInfoRow(
          theme: theme,
          cs: cs,
          icon: Icons.people,
          label: 'Proches assignés',
          value: '${widget.zone.memberIds?.length ?? 0} proche(s)',
        ),
        if (widget.zone.memberIds?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.zone.memberIds!
                .map((memberId) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: cs.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memberId,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  String _getSeverityLabel(DangerSeverity? severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'Faible';
      case DangerSeverity.medium:
        return 'Moyen';
      case DangerSeverity.high:
        return 'Élevé';
      case DangerSeverity.critical:
        return 'Critique';
      default:
        return 'Non défini';
    }
  }

  String _getIconLabel(String iconKey) {
    switch (iconKey) {
      case 'home':
        return 'Maison';
      case 'school':
        return 'École';
      case 'work':
        return 'Travail';
      case 'hospital':
        return 'Hôpital';
      case 'shopping':
        return 'Shopping';
      case 'restaurant':
        return 'Restaurant';
      case 'gym':
        return 'Salle de sport';
      case 'park':
        return 'Parc';
      default:
        return iconKey;
    }
  }
}