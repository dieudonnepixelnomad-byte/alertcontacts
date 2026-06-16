import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme => GoogleFonts.manropeTextTheme(
    const TextTheme(
      // Display
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.2),

      // Titles
      titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleSmall:  TextStyle(fontSize: 17, fontWeight: FontWeight.w500),

      // Body
      bodyLarge:   TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium:  TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
      bodySmall:   TextStyle(fontSize: 13, fontWeight: FontWeight.w400),

      // Labels
      labelLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      labelSmall:  TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
  );
}
