import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF1E6868);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color orange       = Color(0xFFFF8C3C);
  static const Color pink         = Color(0xFFFF5C7A);
  static const Color success      = Color(0xFF22C55E);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color danger       = Color(0xFFEF4444);
  static const Color gravityLow   = Color(0xFFEAB308);
  static const Color gravityMid   = Color(0xFFF97316);
  static const Color gravityHigh  = Color(0xFFEF4444);

  static const Color gray50  = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray900 = Color(0xFF111827);

  // Backwards-compat aliases for code not yet migrated
  static const Color teal      = primary;
  static const Color safe      = success;
  static const Color alert     = orange;
  static const Color dangerLow = gravityLow;
  static const Color dangerMed = gravityMid;
  static const Color dangerHigh = gravityHigh;
}
