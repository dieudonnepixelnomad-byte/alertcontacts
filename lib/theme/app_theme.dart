import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const teal = Color(0xFF006970);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        // surfaces très claires + textes foncés pour lisibilité
        surface: const Color(0xFFF7F9FA),
        surfaceContainerHighest: Colors.white,
        onSurface: const Color(0xFF1C1B1F),
        // accents
        secondary: const Color(0xFF2F4858),
        // erreurs lisibles
        error: const Color(0xFFB00020),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F6F7),
      fontFamily: 'Inter', // si dispo
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: teal.withOpacity(.10),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: base.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: base.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.80),
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.65),
        ),
      ),
      dividerColor: base.colorScheme.outlineVariant,
    );
  }

  static ThemeData dark() => ThemeData.dark(useMaterial3: true);
}
