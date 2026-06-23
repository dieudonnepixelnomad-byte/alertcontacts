import '../services/analytics_service.dart';

/// Exécute [fn] et envoie toute exception à Crashlytics en non-fatal.
/// Retourne null si erreur. Utiliser pour les opérations non-critiques.
///
/// Usage:
///   final result = await runSafe('loadZones', () => _api.getZones());
Future<T?> runSafe<T>(String context, Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (e, stack) {
    AnalyticsService().recordError(e, stack, reason: context);
    return null;
  }
}

/// Comme [runSafe] mais rethrow après log — pour les opérations critiques
/// où l'appelant doit gérer l'erreur.
Future<T> runSafeRethrow<T>(String context, Future<T> Function() fn) async {
  try {
    return await fn();
  } catch (e, stack) {
    AnalyticsService().recordError(e, stack, reason: context);
    rethrow;
  }
}
