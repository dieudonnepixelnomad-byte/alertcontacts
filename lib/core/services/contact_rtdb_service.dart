import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/contact_relation.dart';

/// Snapshot d'une position de proche reçue depuis Firebase Realtime DB.
class RtdbContactSnapshot {
  final String firebaseUid;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? heading;
  final double? speedKmh;
  final DateTime updatedAt;
  final bool isInvisible;
  final int? batteryLevel;

  const RtdbContactSnapshot({
    required this.firebaseUid,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.heading,
    this.speedKmh,
    required this.updatedAt,
    this.isInvisible = false,
    this.batteryLevel,
  });
}

/// Écoute les positions des proches en temps réel via Firebase Realtime DB.
///
/// Structure RDB : /locations/{firebase_uid}
///   lat, lng, accuracy, heading?, updated_at (ms), is_invisible
///
/// Appelé via ChangeNotifierProxyProvider depuis RelationshipProvider.
/// Ouvre/ferme automatiquement les listeners quand les contacts changent.
class ContactRtdbService extends ChangeNotifier {
  static final ContactRtdbService _instance = ContactRtdbService._internal();
  factory ContactRtdbService() => _instance;
  ContactRtdbService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Map<String, StreamSubscription<DatabaseEvent>> _subs = {};
  final Map<String, RtdbContactSnapshot> _snapshots = {};

  Map<String, RtdbContactSnapshot> get snapshots => Map.unmodifiable(_snapshots);

  /// Met à jour les listeners selon la liste courante des proches acceptés.
  /// Ferme les listeners des proches supprimés, ouvre ceux des nouveaux.
  void updateContacts(List<ContactRelation> relations) {
    final activeUids = <String>{
      for (final r in relations)
        if (r.isRealtimeSharing && r.contact.firebaseUid != null)
          r.contact.firebaseUid!,
    };

    developer.log(
      'updateContacts: relations=${relations.length} activeUids=$activeUids',
      name: 'ContactRtdbService',
    );

    // Fermer les listeners des proches qui ne sont plus actifs
    for (final uid in [..._subs.keys]) {
      if (!activeUids.contains(uid)) {
        _subs[uid]?.cancel();
        _subs.remove(uid);
        _snapshots.remove(uid);
      }
    }

    // Ouvrir les nouveaux listeners
    for (final uid in activeUids) {
      if (_subs.containsKey(uid)) continue;
      developer.log('opening listener for uid=$uid', name: 'ContactRtdbService');
      _subs[uid] = _db.ref('locations/$uid').onValue.listen(
        (event) => _onData(uid, event),
        onError: (e) => developer.log(
          'listener error uid=$uid: $e',
          name: 'ContactRtdbService',
        ),
      );
    }

    notifyListeners();
  }

  void _onData(String uid, DatabaseEvent event) {
    final raw = event.snapshot.value;
    developer.log('_onData uid=$uid raw=${raw?.runtimeType} value=$raw', name: 'ContactRtdbService');
    if (raw == null) {
      _snapshots.remove(uid);
      notifyListeners();
      return;
    }
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final rawSpeed = (map['speed'] as num?)?.toDouble();
      _snapshots[uid] = RtdbContactSnapshot(
        firebaseUid: uid,
        latitude: (map['lat'] as num).toDouble(),
        longitude: (map['lng'] as num).toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
        heading: (map['heading'] as num?)?.toDouble(),
        speedKmh: rawSpeed != null ? rawSpeed * 3.6 : null,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        isInvisible: map['is_invisible'] as bool? ?? false,
        batteryLevel: (map['battery'] as num?)?.toInt(),
      );
      developer.log('snapshot stored for uid=$uid lat=${map['lat']} lng=${map['lng']}', name: 'ContactRtdbService');
      notifyListeners();
    } catch (e) {
      developer.log(
        'parse error uid=$uid: $e',
        name: 'ContactRtdbService',
      );
    }
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _snapshots.clear();
    super.dispose();
  }
}
