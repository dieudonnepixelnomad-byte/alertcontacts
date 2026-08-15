import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlertEventCategory { zone, contact }

class AlertEvent {
  final String id;
  final AlertEventCategory category;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  bool isRead;

  AlertEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'subtitle': subtitle,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AlertEvent.fromJson(Map<String, dynamic> json) => AlertEvent(
        id: json['id'] as String,
        category: AlertEventCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => AlertEventCategory.zone,
        ),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

/// Stocke localement les events zone + contact reçus via FCM ou géofencing local.
/// Persisté dans SharedPreferences, max 50 entrées, plus récent en tête.
class AlertEventStore extends ChangeNotifier {
  static final AlertEventStore _instance = AlertEventStore._internal();
  factory AlertEventStore() => _instance;
  AlertEventStore._internal();

  static const String _prefsKey = 'alert_event_store_v1';
  static const int _maxEvents = 50;

  /// Fenêtre d'historique des alertes — CDC §10.1.
  static const int freeRetentionHours = 24;      // tier Gratuit
  static const int paidRetentionHours = 24 * 30; // Solo / Famille — 30 jours

  final List<AlertEvent> _events = [];
  bool _loaded = false;

  /// Fenêtre actuellement appliquée. Défaut prudent sur le tier Gratuit :
  /// tant que le profil n'est pas chargé, on n'expose jamais plus que le
  /// minimum garanti. Voir [applyTier].
  int _retentionHours = freeRetentionHours;

  int get retentionHours => _retentionHours;

  /// Ajuste la fenêtre selon le tier de l'utilisateur ('free' | 'solo' | 'famille').
  /// À appeler dès que le profil est connu, et à chaque changement d'abonnement.
  void applyTier(String tier) {
    final hours = (tier == 'solo' || tier == 'famille')
        ? paidRetentionHours
        : freeRetentionHours;
    if (hours == _retentionHours) return;
    _retentionHours = hours;
    notifyListeners();
    log('[AlertEventStore] retention → ${hours}h (tier: $tier)');
  }

  /// Le filtrage est volontairement fait à la lecture, jamais par suppression :
  /// un utilisateur qui souscrit doit retrouver son historique, et un profil
  /// pas encore chargé ne doit pas détruire les données d'un abonné.
  bool _isWithinRetention(AlertEvent e) =>
      DateTime.now().difference(e.createdAt).inHours < _retentionHours;

  List<AlertEvent> get events =>
      List.unmodifiable(_events.where(_isWithinRetention));

  List<AlertEvent> get zoneEvents => _events
      .where((e) => e.category == AlertEventCategory.zone && _isWithinRetention(e))
      .toList();

  List<AlertEvent> get contactEvents => _events
      .where((e) => e.category == AlertEventCategory.contact && _isWithinRetention(e))
      .toList();

  int get unreadCount =>
      _events.where((e) => !e.isRead && _isWithinRetention(e)).length;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _events.clear();
        _events.addAll(
          list.map((e) => AlertEvent.fromJson(e as Map<String, dynamic>)),
        );
      }
      _pruneExpired();
      _loaded = true;
      log('[AlertEventStore] loaded ${_events.length} events');
    } catch (e) {
      log('[AlertEventStore] load error: $e');
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_events.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      log('[AlertEventStore] persist error: $e');
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void addZoneEntry({required String zoneName, required String contactName}) {
    _push(AlertEvent(
      id: _newId(),
      category: AlertEventCategory.zone,
      title: '$contactName est arrivé(e)',
      subtitle: zoneName,
      createdAt: DateTime.now(),
    ));
  }

  void addZoneExit({required String zoneName, required String contactName}) {
    _push(AlertEvent(
      id: _newId(),
      category: AlertEventCategory.zone,
      title: '$contactName a quitté',
      subtitle: zoneName,
      createdAt: DateTime.now(),
    ));
  }

  void addContactAlert({required String title, required String subtitle}) {
    _push(AlertEvent(
      id: _newId(),
      category: AlertEventCategory.contact,
      title: title,
      subtitle: subtitle,
      createdAt: DateTime.now(),
    ));
  }

  /// Purge définitive au-delà de la fenêtre la plus large (30 j) : passé ce
  /// délai, aucun tier ne peut plus afficher l'event, le garder ne sert à rien.
  void _pruneExpired() {
    final cutoff = DateTime.now().subtract(
      const Duration(hours: paidRetentionHours),
    );
    final before = _events.length;
    _events.removeWhere((e) => e.createdAt.isBefore(cutoff));
    if (_events.length != before) {
      _persist();
      log('[AlertEventStore] pruned ${before - _events.length} expired events');
    }
  }

  void _push(AlertEvent event) {
    _events.insert(0, event);
    _pruneExpired();
    if (_events.length > _maxEvents) _events.removeLast();
    _persist();
    notifyListeners();
    log('[AlertEventStore] event added: ${event.category.name} — ${event.title}');
  }

  void markRead(String id) {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx >= 0 && !_events[idx].isRead) {
      _events[idx].isRead = true;
      _persist();
      notifyListeners();
    }
  }

  void markAllRead({AlertEventCategory? category}) {
    var changed = false;
    for (final e in _events) {
      if ((category == null || e.category == category) && !e.isRead) {
        e.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  bool isRead(String id) {
    final idx = _events.indexWhere((e) => e.id == id);
    return idx < 0 || _events[idx].isRead;
  }
}
