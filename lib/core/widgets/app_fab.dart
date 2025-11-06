import 'package:flutter/material.dart';

/// Widget réutilisable pour créer des boutons flottants avec libellés
class LabeledFloatingActionButton extends StatelessWidget {
  final String heroTag;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final bool showLabel;
  final bool autoHideOnSmallScreen;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? labelStyle;
  final String? tooltip;

  const LabeledFloatingActionButton({
    super.key,
    required this.heroTag,
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    this.showLabel = true,
    this.autoHideOnSmallScreen = true,
    this.labelPadding,
    this.labelStyle,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Déterminer si on doit afficher le libellé basé sur la taille d'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldShowLabel = showLabel && 
        (!autoHideOnSmallScreen || screenWidth > 300); // Seuil plus bas pour plus de compatibilité

    final fabButton = FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      elevation: 6,
      tooltip: tooltip ?? label,
      child: Icon(icon, color: Colors.white, size: 24),
    );

    if (!shouldShowLabel) {
      return fabButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Libellé avec animation et design amélioré
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: labelPadding ?? 
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: backgroundColor.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: backgroundColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: labelStyle ?? TextStyle(
              color: backgroundColor.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton flottant
        fabButton,
      ],
    );
  }
}

/// Widget pour créer une colonne de boutons flottants avec libellés
class LabeledFloatingActionButtonColumn extends StatelessWidget {
  final List<LabeledFloatingActionButton> buttons;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const LabeledFloatingActionButtonColumn({
    super.key,
    required this.buttons,
    this.spacing = 12.0,
    this.crossAxisAlignment = CrossAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: buttons
          .expand((button) => [button, SizedBox(height: spacing)])
          .take(buttons.length * 2 - 1)
          .toList(),
    );
  }
}

/// Widget pour créer une rangée de boutons flottants avec libellés
class LabeledFloatingActionButtonRow extends StatelessWidget {
  final List<LabeledFloatingActionButton> buttons;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  const LabeledFloatingActionButtonRow({
    super.key,
    required this.buttons,
    this.spacing = 12.0,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: buttons
          .expand((button) => [button, SizedBox(width: spacing)])
          .take(buttons.length * 2 - 1)
          .toList(),
    );
  }
}