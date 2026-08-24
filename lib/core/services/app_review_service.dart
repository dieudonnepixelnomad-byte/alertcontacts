import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Gère les sollicitations d'avis sans dépendre d'un serveur ni de données
/// personnelles. Google Play reste libre d'afficher ou non son interface.
class AppReviewService {
  AppReviewService({
    SharedPreferences? preferences,
    DateTime Function()? now,
    InAppReview? inAppReview,
  })  : _preferences = preferences,
        _now = now ?? DateTime.now,
        _inAppReview = inAppReview ?? InAppReview.instance;

  static const _firstUseAtKey = 'app_review_first_use_at';
  static const _successfulValueEventsKey = 'app_review_successful_value_events';
  static const _lastPromptAtKey = 'app_review_last_prompt_at';
  static const _lastErrorAtKey = 'app_review_last_error_at';
  static const _declineCountKey = 'app_review_decline_count';
  static const _safetyAhaMomentAtKey = 'app_review_safety_aha_moment_at';

  static const minimumSuccessfulValueEvents = 3;
  static const minimumUseDuration = Duration(days: 7);
  static const promptCooldown = Duration(days: 90);
  static const errorQuietPeriod = Duration(hours: 48);
  static const maximumDeclines = 2;

  final SharedPreferences? _preferences;
  final DateTime Function() _now;
  final InAppReview _inAppReview;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  /// À appeler dès le démarrage. Le délai ne dépend donc pas de la première
  /// action métier accomplie par l'utilisateur.
  Future<void> initialize() async {
    final prefs = await _prefs;
    if (!prefs.containsKey(_firstUseAtKey)) {
      await prefs.setInt(_firstUseAtKey, _now().millisecondsSinceEpoch);
    }
  }

  /// À appeler uniquement après la confirmation d'une action qui a apporté une
  /// valeur réelle (zone créée, proche connecté, alerte communautaire publiée).
  Future<bool> registerSuccessfulValueEvent() async {
    await initialize();
    final prefs = await _prefs;
    final eventCount = prefs.getInt(_successfulValueEventsKey) ?? 0;
    await prefs.setInt(_successfulValueEventsKey, eventCount + 1);
    return isEligible();
  }

  /// Première preuve visible que la boucle de sécurité fonctionne : un proche
  /// affecté à une zone est localisé avec une position fraîche dans cette zone.
  Future<bool> registerSafetyAhaMoment() async {
    await initialize();
    final prefs = await _prefs;
    if (!prefs.containsKey(_safetyAhaMomentAtKey)) {
      await prefs.setInt(_safetyAhaMomentAtKey, _now().millisecondsSinceEpoch);
      final eventCount = prefs.getInt(_successfulValueEventsKey) ?? 0;
      await prefs.setInt(_successfulValueEventsKey, eventCount + 1);
      AnalyticsService().logSafetyAhaMomentConfirmed();
    }
    return isEligible();
  }

  /// Enregistre une erreur qui vient d'être montrée ou remontée à l'utilisateur.
  /// Les demandes sont alors suspendues pendant une période calme.
  Future<void> recordRecentError() async {
    final prefs = await _prefs;
    await prefs.setInt(_lastErrorAtKey, _now().millisecondsSinceEpoch);
  }

  Future<bool> isEligible() async {
    final prefs = await _prefs;
    final now = _now();
    final firstUseAt = prefs.getInt(_firstUseAtKey);
    if (firstUseAt == null ||
        now.difference(DateTime.fromMillisecondsSinceEpoch(firstUseAt)) <
            minimumUseDuration) {
      return false;
    }
    if ((prefs.getInt(_successfulValueEventsKey) ?? 0) <
        minimumSuccessfulValueEvents) {
      return false;
    }
    if (!prefs.containsKey(_safetyAhaMomentAtKey)) return false;
    if ((prefs.getInt(_declineCountKey) ?? 0) >= maximumDeclines) {
      return false;
    }
    if (_isWithin(prefs.getInt(_lastPromptAtKey), promptCooldown, now) ||
        _isWithin(prefs.getInt(_lastErrorAtKey), errorQuietPeriod, now)) {
      return false;
    }
    return true;
  }

  bool _isWithin(int? timestamp, Duration duration, DateTime now) {
    if (timestamp == null) return false;
    return now.difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) <
        duration;
  }

  /// Présente les deux canaux à égalité : avis public ou retour privé. Aucun
  /// choix ne conditionne l'accès à Google Play, afin d'éviter le review gating.
  Future<AppReviewPromptChoice?> showPrompt(BuildContext context) async {
    if (!await isEligible() || !context.mounted) return null;

    final choice = await showDialog<AppReviewPromptChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Votre expérience compte'),
        content: const Text(
          'AlertContacts vous aide à garder l’esprit plus tranquille ?\n\n'
          'Votre avis public aide d’autres familles à découvrir l’application. '
          'Votre retour privé nous aide à la rendre plus fiable.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, AppReviewPromptChoice.later),
            child: const Text('Pas maintenant'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, AppReviewPromptChoice.feedback),
            child: const Text('Envoyer un retour'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, AppReviewPromptChoice.review),
            child: const Text('Donner un avis'),
          ),
        ],
      ),
    );

    if (choice == null) return null;
    final prefs = await _prefs;
    await prefs.setInt(_lastPromptAtKey, _now().millisecondsSinceEpoch);

    if (choice == AppReviewPromptChoice.later) {
      await prefs.setInt(
        _declineCountKey,
        (prefs.getInt(_declineCountKey) ?? 0) + 1,
      );
      AnalyticsService().logAppReviewPrompt(action: 'later');
      return choice;
    }
    if (choice == AppReviewPromptChoice.feedback) {
      AnalyticsService().logAppReviewPrompt(action: 'feedback');
      return choice;
    }

    AnalyticsService().logAppReviewPrompt(action: 'requested');
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
      // Une indisponibilité du flux Play ne doit jamais perturber le succès métier.
    }
    return choice;
  }

  /// Action volontaire depuis les paramètres : ouvre directement la fiche Store.
  Future<void> openStoreListing() async {
    AnalyticsService().logAppReviewPrompt(action: 'store_listing_opened');
    try {
      await _inAppReview.openStoreListing();
    } catch (_) {
      // Le bouton manuel reste sans effet si aucun store compatible n'est présent.
    }
  }
}

enum AppReviewPromptChoice { review, feedback, later }
