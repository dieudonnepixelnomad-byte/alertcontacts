import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlertAcknowledgmentService {
  static final AlertAcknowledgmentService _instance =
      AlertAcknowledgmentService._internal();
  factory AlertAcknowledgmentService() => _instance;
  AlertAcknowledgmentService._internal();

  static const _key = 'acknowledged_alert_ids';
  Set<String> _acknowledgedIds = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = List<String>.from(jsonDecode(raw) as List);
      _acknowledgedIds = list.toSet();
    }
  }

  Future<void> acknowledgeAlert(String id) async {
    _acknowledgedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_acknowledgedIds.toList()));
  }

  bool isAcknowledged(String id) => _acknowledgedIds.contains(id);

  Set<String> get acknowledgedIds => Set.unmodifiable(_acknowledgedIds);
}
