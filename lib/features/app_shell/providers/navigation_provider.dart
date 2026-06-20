import 'package:flutter/material.dart';

class FocusContactRequest {
  final String uid;
  final double lat;
  final double lng;
  FocusContactRequest({required this.uid, required this.lat, required this.lng});
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  FocusContactRequest? _pendingFocus;

  int get currentIndex => _currentIndex;
  FocusContactRequest? get pendingFocus => _pendingFocus;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToMap() => setIndex(0);
  void goToProches() => setIndex(1);
  void goToAlertes() => setIndex(2);

  void focusContact({required String uid, required double lat, required double lng}) {
    _pendingFocus = FocusContactRequest(uid: uid, lat: lat, lng: lng);
    _currentIndex = 0;
    notifyListeners();
  }

  void clearFocus() {
    _pendingFocus = null;
  }
}