import 'package:flutter/material.dart';
import 'package:alertcontacts/generated/l10n/app_localizations.dart';

/// Helper pour accéder facilement aux traductions dans toute l'application
class L10n {
  /// Récupère les traductions depuis le contexte
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  /// Vérifie si une locale est supportée
  static bool isSupported(Locale locale) {
    return AppLocalizations.delegate.isSupported(locale);
  }

  /// Récupère la liste des locales supportées
  static List<Locale> get supportedLocales {
    return const [
      Locale('fr', ''), // Français
      Locale('en', ''), // Anglais
    ];
  }
}

/// Extension pour accéder facilement aux traductions depuis un BuildContext
extension BuildContextL10n on BuildContext {
  /// Récupère les traductions depuis le contexte
  AppLocalizations get l10n => L10n.of(this);
}
