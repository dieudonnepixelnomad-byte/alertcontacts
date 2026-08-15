import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/prefs_service.dart';

/// Type de carte Google Maps partagé et mémorisé pour toute l'app.
class MapTypeNotifier extends ChangeNotifier {
  MapTypeNotifier(this._prefs) {
    _load();
  }

  final PrefsService _prefs;

  MapType _type = MapType.hybrid;
  MapType get type => _type;

  Future<void> _load() async {
    final saved = await _prefs.getMapType();
    final restored = _mapTypeFromName(saved);
    if (restored != null && restored != _type) {
      _type = restored;
      notifyListeners();
    }
  }

  Future<void> setType(MapType type) async {
    if (type == _type) return;
    _type = type;
    notifyListeners();
    await _prefs.setMapType(type.name);
  }

  MapType? _mapTypeFromName(String? name) {
    if (name == null) return null;
    for (final value in MapType.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
