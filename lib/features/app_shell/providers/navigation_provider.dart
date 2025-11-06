import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToMap() => setIndex(0);
  void goToZones() => setIndex(1);
  void goToProches() => setIndex(2);
  void goToActivity() => setIndex(3);
}