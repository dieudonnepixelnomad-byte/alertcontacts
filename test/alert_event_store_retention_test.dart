import 'dart:convert';

import 'package:alertcontacts/core/services/alert_event_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CDC §10.1 — fenêtre d'historique des alertes : 24 h en tier Gratuit,
/// 30 jours en Solo/Famille.
///
/// Le point délicat est que le filtrage doit être NON DESTRUCTIF : au démarrage
/// le tier n'est pas encore connu et le store retombe sur la fenêtre Gratuit.
/// Si ce repli supprimait les events, un abonné perdrait définitivement son
/// historique à chaque lancement de l'app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> event(String id, Duration age) => {
        'id': id,
        'category': 'zone',
        'title': 'Léa est arrivée',
        'subtitle': 'École',
        'createdAt': DateTime.now().subtract(age).toIso8601String(),
        'isRead': false,
      };

  test('la fenêtre suit le tier sans jamais détruire les events récupérables',
      () async {
    SharedPreferences.setMockInitialValues({
      'alert_event_store_v1': jsonEncode([
        event('recent', const Duration(hours: 2)),
        event('hier', const Duration(hours: 30)),
        event('vieux', const Duration(days: 40)),
      ]),
    });

    final store = AlertEventStore();
    await store.load();

    // Défaut prudent : tier Gratuit tant que le profil n'est pas chargé.
    expect(store.retentionHours, AlertEventStore.freeRetentionHours);
    expect(store.zoneEvents.map((e) => e.id), ['recent']);
    expect(store.unreadCount, 1);

    // Le profil arrive : un abonné retrouve les 30 jours, y compris l'event
    // masqué un instant plus tôt — il n'a donc pas été supprimé.
    store.applyTier('solo');
    expect(store.retentionHours, AlertEventStore.paidRetentionHours);
    expect(store.zoneEvents.map((e) => e.id), ['recent', 'hier']);
    expect(store.unreadCount, 2);

    // Au-delà de 30 jours, plus aucun tier ne peut l'afficher : purgé au load.
    expect(store.zoneEvents.any((e) => e.id == 'vieux'), isFalse);

    // Retour au tier Gratuit (fin d'abonnement) : la fenêtre se referme.
    store.applyTier('free');
    expect(store.zoneEvents.map((e) => e.id), ['recent']);
  });
}
