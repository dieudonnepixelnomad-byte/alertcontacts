import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/zone.dart';
import '../../../theme/colors.dart';

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
    final isDanger = widget.zone.type == ZoneType.danger;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Détails de la zone',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isDanger ? AppColors.alert : AppColors.safe,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                          ? AppColors.alert.withOpacity(0.1)
                          : AppColors.safe.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDanger ? Icons.warning : Icons.shield,
                      color: isDanger ? AppColors.alert : AppColors.safe,
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
                      color: isDanger ? AppColors.alert : AppColors.safe,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDanger ? 'Zone de danger' : 'Zone de sécurité',
                      style: const TextStyle(
                        color: Colors.white,
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
                      fillColor: (isDanger ? AppColors.alert : AppColors.safe)
                          .withOpacity(0.2),
                      strokeColor: (isDanger ? AppColors.alert : AppColors.safe)
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
              title: 'Informations générales',
              children: [
                _buildInfoRow(
                  icon: Icons.radio_button_unchecked,
                  label: 'Rayon',
                  value: '${widget.zone.radiusMeters.toStringAsFixed(0)} mètres',
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Coordonnées',
                  value:
                      '${widget.zone.center.lat.toStringAsFixed(6)}, ${widget.zone.center.lng.toStringAsFixed(6)}',
                ),
                if (widget.zone.address?.isNotEmpty == true)
                  _buildInfoRow(
                    icon: Icons.place,
                    label: 'Adresse',
                    value: widget.zone.address!,
                  ),
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: 'Créée le',
                  value:
                      DateFormat('dd/MM/yyyy à HH:mm').format(widget.zone.createdAt),
                ),
                _buildInfoRow(
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
                title: 'Description',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
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
              _buildDangerSpecificInfo(),
            ] else ...[
              _buildSafeSpecificInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
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
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildDangerSpecificInfo() {
    return _buildInfoSection(
      title: 'Informations de danger',
      children: [
        _buildInfoRow(
          icon: Icons.priority_high,
          label: 'Niveau de sévérité',
          value: _getSeverityLabel(widget.zone.severity),
        ),
        _buildInfoRow(
          icon: Icons.verified,
          label: 'Confirmations',
          value: '${widget.zone.confirmations ?? 0} confirmation(s)',
        ),
        if (widget.zone.lastReportAt != null)
          _buildInfoRow(
            icon: Icons.report,
            label: 'Dernier signalement',
            value: DateFormat('dd/MM/yyyy à HH:mm')
                .format(widget.zone.lastReportAt!),
          ),
      ],
    );
  }

  Widget _buildSafeSpecificInfo() {
    return _buildInfoSection(
      title: 'Informations de sécurité',
      children: [
        if (widget.zone.iconKey?.isNotEmpty == true)
          _buildInfoRow(
            icon: Icons.category,
            label: 'Catégorie',
            value: _getIconLabel(widget.zone.iconKey!),
          ),
        _buildInfoRow(
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
                        color: AppColors.safe.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.safe.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.safe,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memberId,
                            style: TextStyle(
                              color: AppColors.safe,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
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