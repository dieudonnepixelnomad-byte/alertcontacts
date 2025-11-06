// lib/features/zones_securite/presentation/widgets/zone_name_icon_step.dart
import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class ZoneNameIconStep extends StatefulWidget {
  final String initialName;
  final String initialIconKey;
  final void Function(String name, String iconKey) onChanged;
  final VoidCallback onNext;

  const ZoneNameIconStep({
    super.key,
    required this.initialName,
    required this.initialIconKey,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<ZoneNameIconStep> createState() => _ZoneNameIconStepState();
}

class _ZoneNameIconStepState extends State<ZoneNameIconStep> {
  late final TextEditingController _ctrl;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _iconKey = widget.initialIconKey;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final icons = {
      'home': {'icon': Icons.home, 'label': 'Maison'},
      'school': {'icon': Icons.school, 'label': 'École'},
      'park': {'icon': Icons.park, 'label': 'Parc'},
      'work': {'icon': Icons.apartment, 'label': 'Travail'},
      'heart': {'icon': Icons.favorite, 'label': 'Favori'},
      'gym': {'icon': Icons.fitness_center, 'label': 'Sport'},
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur de progression
          //_buildProgressIndicator(context, currentStep: 2, totalSteps: 4),
          const SizedBox(height: 32),

          // Titre
          Text(
            'Configuration de la zone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Donnez un nom à votre zone et choisissez une icône.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 32),

          // Champ nom
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: 'Nom de la zone',
              hintText: 'Maison, École, Travail...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.teal, width: 2),
              ),
            ),
            onChanged: (_) => widget.onChanged(_ctrl.text, _iconKey),
          ),

          const SizedBox(height: 32),

          // Section icônes
          Text(
            'Choisissez une icône',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // Grille d'icônes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final entry = icons.entries.elementAt(index);
              final key = entry.key;
              final iconData = entry.value;
              final selected = _iconKey == key;

              return GestureDetector(
                onTap: () {
                  setState(() => _iconKey = key);
                  widget.onChanged(_ctrl.text, _iconKey);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal : cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.teal
                          : cs.outline.withOpacity(0.2),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconData['icon'] as IconData,
                        size: 32,
                        color: selected ? Colors.white : AppColors.teal,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        iconData['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Bouton suivant
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _ctrl.text.trim().isNotEmpty ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.teal.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: cs.onSurface.withOpacity(0.1),
              ),
              child: const Text(
                'Suivant',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required int currentStep,
    required int totalSteps,
  }) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive || isCurrent
                  ? AppColors.teal
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
        );
      }),
    );
  }
}
