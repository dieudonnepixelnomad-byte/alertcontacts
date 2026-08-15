import 'package:flutter/material.dart';

/// Barre de recherche flottante « Où vas-tu ? » — CDC V4.1 §6.1
///
/// Le module Trajets n'ajoute PAS de quatrième onglet : la barre d'onglets
/// reste à trois entrées. Il s'intègre à l'onglet Carte via cette barre
/// flottante placée sous le header — convention établie par Google Maps,
/// Apple Plans et Waze, aucun emplacement de navigation consommé,
/// découvrabilité maximale.
///
/// Elle est en zone haute (§12.4) mais n'est qu'un point d'entrée : toutes les
/// actions décisionnelles restent en zone basse.
class RouteSearchBar extends StatelessWidget {
  const RouteSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      // §11.2 — hauteur 48 dp, coins 24 dp, ombre portée légère
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Où vas-tu ?',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
