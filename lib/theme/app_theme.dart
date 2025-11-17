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

  static ThemeData dark() {
    const teal = Color(0xFF4DB6AC); // Teal plus clair pour mode sombre
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        brightness: Brightness.dark,
        // Surfaces sombres avec bon contraste
        surface: const Color(0xFF1E1E1E),
        surfaceContainerHighest: const Color(0xFF2D2D2D),
        onSurface: const Color(0xFFE0E0E0),
        // Couleurs adaptées au mode sombre
        secondary: const Color(0xFF80CBC4),
        error: const Color(0xFFCF6679),
        // Fond général
        background: const Color(0xFF121212),
        onBackground: const Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: base.colorScheme.surface,
        indicatorColor: teal.withOpacity(.20),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Configuration spéciale pour les TextFields en mode sombre
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.error, width: 1),
        ),
        labelStyle: TextStyle(
          color: base.colorScheme.onSurface.withOpacity(0.7),
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: base.colorScheme.onSurface.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIconColor: base.colorScheme.onSurface.withOpacity(0.6),
        suffixIconColor: base.colorScheme.onSurface.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          color: base.colorScheme.onSurface.withOpacity(.90),
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.75),
        ),
      ),
      dividerColor: base.colorScheme.outline.withOpacity(0.2),
      // Couleurs pour les cartes et surfaces élevées
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: base.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
    );
  }
}
