import 'package:flutter/material.dart';

/// Palette centrale (charte)
class AppColors {
  // Couleur principale (teal profond)
  static const teal = Color(0xFF006970);

  // Accents
  static const safe = Color(0xFF4CAF50); // vert sécurité
  static const alert = Color(0xFFFF6B35); // orange/rouge alerte

  // Échelle danger (pour gravité)
  static const dangerLow = Color(0xFFFFA726); // orange
  static const dangerMed = Color(0xFFEF5350); // rouge moyen
  static const dangerHigh = Color(0xFFB71C1C); // rouge foncé

  // Gris UI
  static const gray50 = Color(0xFFF4F4F4);
  static const gray100 = Color(0xFFEAEAEA);
  static const gray700 = Color(0xFF4A4A4A);
  static const gray900 = Color(0xFF1F1F1F);
}
