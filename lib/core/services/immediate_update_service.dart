import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

/// Utilise le flux Play Store plein écran pour les mises à jour critiques.
/// Retourne false lorsque l'app n'a pas été installée par Google Play ou
/// lorsqu'aucune mise à jour immédiate n'est disponible.
class ImmediateUpdateService {
  Future<bool> startIfAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }
}
