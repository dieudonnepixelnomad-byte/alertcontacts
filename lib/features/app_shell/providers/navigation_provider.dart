import 'package:flutter/material.dart';

class MapFocusRequest {
  final double lat;
  final double lng;
  const MapFocusRequest({required this.lat, required this.lng});
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  MapFocusRequest? _pendingFocus;

  int get currentIndex => _currentIndex;
  MapFocusRequest? get pendingFocus => _pendingFocus;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToMap() => setIndex(0);
  void goToProches() => setIndex(1);
  void goToAlertes() => setIndex(2);
  void goToTraceurs() => setIndex(3);

  void focusContact({required String uid, required double lat, required double lng}) {
    _pendingFocus = MapFocusRequest(lat: lat, lng: lng);
    _currentIndex = 0;
    notifyListeners();
  }

  /// Centre la carte sur une coordonnée qui ne correspond pas nécessairement à
  /// un proche : incident communautaire, zone, ou résultat de recherche.
  void focusLocation({required double lat, required double lng}) {
    _pendingFocus = MapFocusRequest(lat: lat, lng: lng);
    _currentIndex = 0;
    notifyListeners();
  }

  void clearFocus() {
    _pendingFocus = null;
  }
}
