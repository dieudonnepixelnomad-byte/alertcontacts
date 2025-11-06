import 'package:flutter/material.dart';

/// Typographies (tu peux brancher GoogleFonts si tu ajoutes la dépendance)
class AppTypography {
  static const String displayFont = 'Montserrat'; // optionnel si déclaré
  static const String bodyFont = 'Roboto'; // optionnel si déclaré

  static TextTheme textTheme =
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ).apply(
        fontFamily: bodyFont,
        // Tu peux affiner par style si tu déclares deux familles distinctes
      );
}
