import 'package:flutter/material.dart';
import '../../../../core/models/danger_zone.dart';
import '../../../../core/enums/danger_type.dart';
import '../../../../theme/colors.dart';

class DangerZoneInfoStep extends StatelessWidget {
  final String title;
  final String description;
  final DangerSeverity severity;
  final DangerType dangerType;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<DangerSeverity> onSeverityChanged;
  final ValueChanged<DangerType> onDangerTypeChanged;

  const DangerZoneInfoStep({
    super.key,
    required this.title,
    required this.description,
    required this.severity,
    required this.dangerType,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onSeverityChanged,
    required this.onDangerTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          Text(
            'Informations sur le danger',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Décrivez le danger que vous souhaitez signaler',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Champ titre
          _buildTitleField(context),
          const SizedBox(height: 24),

          // Sélecteur de type de danger
          _buildDangerTypeSelector(context),
          const SizedBox(height: 24),

          // Sélecteur de gravité
          _buildSeveritySelector(context),
          const SizedBox(height: 24),

          // Champ description
          _buildDescriptionField(context),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Titre du danger *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: title,
          onChanged: onTitleChanged,
          decoration: InputDecoration(
            hintText: 'Ex: Agression, Vol, Zone dangereuse...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.alert, width: 2),
            ),
            filled: true,
            fillColor: cs.surface,
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildDangerTypeSelector(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de danger *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.onSurface.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<DangerType>(
            isExpanded: true,
            itemHeight: null,
            initialValue: dangerType,
            onChanged: (DangerType? newValue) {
              if (newValue != null) {
                onDangerTypeChanged(newValue);
              }
            },
            selectedItemBuilder: (context) {
              return DangerType.values.map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(type.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        type.label, // une seule ligne suffit quand sélectionné
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: cs.surface,
            ),
            items: DangerType.values.map((DangerType type) {
              return DropdownMenuItem<DangerType>(
                value: type,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(type.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            dropdownColor: cs.surface,
            style: TextStyle(color: cs.onSurface),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeveritySelector(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveau de gravité *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: DangerSeverity.values.map((sev) {
            final isSelected = severity == sev;
            final color = _getSeverityColor(sev);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: sev != DangerSeverity.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onSeverityChanged(sev),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? color : cs.surface,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : cs.onSurface.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getSeverityIcon(sev),
                          color: isSelected ? Colors.white : color,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getSeverityLabel(sev),
                          style: TextStyle(
                            color: isSelected ? Colors.white : cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optionnel)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: description,
          onChanged: onDescriptionChanged,
          decoration: InputDecoration(
            hintText: 'Ajoutez des détails sur le danger...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.alert, width: 2),
            ),
            filled: true,
            fillColor: cs.surface,
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 4,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Color _getSeverityColor(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return AppColors.dangerLow;
      case DangerSeverity.med:
        return AppColors.dangerMed;
      case DangerSeverity.high:
        return AppColors.dangerHigh;
    }
  }

  IconData _getSeverityIcon(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return Icons.info_outline;
      case DangerSeverity.med:
        return Icons.warning_amber_outlined;
      case DangerSeverity.high:
        return Icons.dangerous_outlined;
    }
  }

  String _getSeverityLabel(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.low:
        return 'Faible';
      case DangerSeverity.med:
        return 'Modéré';
      case DangerSeverity.high:
        return 'Élevé';
    }
  }
}
