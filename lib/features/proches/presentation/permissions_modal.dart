import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PermissionsModal extends StatefulWidget {
  final String contactName;
  final String avatarUrl;
  final DateTime? acceptedAt;
  final bool sharePosition;
  final bool shareBattery;
  final bool shareZoneEvents;
  final bool shareSpeed;
  final Future<bool> Function({
    required bool sharePosition,
    required bool shareBattery,
    required bool shareZoneEvents,
    required bool shareSpeed,
  }) onSave;

  const PermissionsModal({
    super.key,
    required this.contactName,
    required this.onSave,
    this.avatarUrl = '',
    this.acceptedAt,
    this.sharePosition = true,
    this.shareBattery = true,
    this.shareZoneEvents = true,
    this.shareSpeed = false,
  });

  @override
  State<PermissionsModal> createState() => _PermissionsModalState();
}

class _PermissionsModalState extends State<PermissionsModal> {
  late bool _sharePosition;
  late bool _shareBattery;
  late bool _shareZoneEvents;
  late bool _shareSpeed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sharePosition = widget.sharePosition;
    _shareBattery = widget.shareBattery;
    _shareZoneEvents = widget.shareZoneEvents;
    _shareSpeed = widget.shareSpeed;
  }

  bool get _hasChanges =>
      _sharePosition != widget.sharePosition ||
      _shareBattery != widget.shareBattery ||
      _shareZoneEvents != widget.shareZoneEvents ||
      _shareSpeed != widget.shareSpeed;

  String _formatDate(DateTime dt) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return 'le ${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final firstName = widget.contactName.split(' ').first;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text('Permissions de partage', style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Ce que $firstName peut voir de toi',
                  style: tt.bodySmall?.copyWith(color: AppColors.gray400),
                ),
                const SizedBox(height: 16),

                // Contact info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: widget.avatarUrl.isNotEmpty
                            ? NetworkImage(widget.avatarUrl)
                            : null,
                        child: widget.avatarUrl.isEmpty
                            ? Text(
                                widget.contactName.isNotEmpty
                                    ? widget.contactName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contactName,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (widget.acceptedAt != null)
                            Text(
                              'Connecté(e) depuis ${_formatDate(widget.acceptedAt!)}',
                              style: tt.labelMedium?.copyWith(color: AppColors.gray400),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Permission tiles
                _PermissionTile(
                  icon: Icons.location_on_outlined,
                  label: 'Ma position en temps réel',
                  description: 'Visible sur la carte',
                  value: _sharePosition,
                  onChanged: (v) => setState(() => _sharePosition = v),
                ),
                _PermissionTile(
                  icon: Icons.battery_5_bar_outlined,
                  label: 'Niveau de batterie',
                  description: 'Pour qu\'il/elle sache',
                  value: _shareBattery,
                  onChanged: (v) => setState(() => _shareBattery = v),
                ),
                _PermissionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Entrées et sorties de zone',
                  description: 'Notifications automatiques',
                  value: _shareZoneEvents,
                  onChanged: (v) => setState(() => _shareZoneEvents = v),
                ),
                _PermissionTile(
                  icon: Icons.speed_outlined,
                  label: 'Vitesse de déplacement',
                  description: 'En km/h',
                  value: _shareSpeed,
                  onChanged: (v) => setState(() => _shareSpeed = v),
                ),
                const SizedBox(height: 16),

                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$firstName ne peut pas voir tes alertes communautaires privées.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray600,
                          side: const BorderSide(color: AppColors.gray200),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_hasChanges && !_saving) ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.gray200,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Enregistrer',
                                style: tt.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(
      sharePosition: _sharePosition,
      shareBattery: _shareBattery,
      shareZoneEvents: _shareZoneEvents,
      shareSpeed: _shareSpeed,
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'enregistrer les permissions')),
        );
      }
    }
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryLight : AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppColors.primary : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(description, style: tt.labelMedium?.copyWith(color: AppColors.gray400)),
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
      ),
    );
  }
}
