import 'package:flutter/foundation.dart';
import '../services/alert_service.dart';

enum AlertStatus {
  uninitialized,
  initializing,
  ready,
  error,
}

/// Provider d'alertes simplifié
/// 
/// Ce provider gère uniquement la configuration des notifications.
/// La surveillance des zones et la détection de proximité sont gérées par le backend.
class AlertProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();

  AlertStatus _status = AlertStatus.uninitialized;
  String? _errorMessage;

  AlertProvider() {
    _alertService.addListener(_onAlertServiceChanged);
  }

  // Getters
  AlertStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _alertService.isInitialized;

  void _onAlertServiceChanged() {
    notifyListeners();
  }

  /// Initialiser le service d'alertes
  Future<void> initialize() async {
    if (_status != AlertStatus.uninitialized) return;

    try {
      _updateStatus(AlertStatus.initializing);

      await _alertService.initialize();

      _updateStatus(AlertStatus.ready);
      debugPrint('AlertProvider: Initialized successfully');
    } catch (e) {
      _updateStatus(AlertStatus.error, 'Erreur d\'initialisation: $e');
      debugPrint('AlertProvider: Initialization error: $e');
    }
  }

  /// Obtenir les statistiques du service
  Map<String, dynamic> getStatistics() {
    return _alertService.getStatistics();
  }

  /// Redémarrer le service d'alertes
  Future<void> restart() async {
    try {
      _clearError();
      await initialize();
      debugPrint('AlertProvider: Service restarted');
    } catch (e) {
      _setError('Erreur lors du redémarrage: $e');
      debugPrint('AlertProvider: Error restarting service: $e');
    }
  }

  void _updateStatus(AlertStatus newStatus, [String? error]) {
    _status = newStatus;
    _errorMessage = error;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertService.removeListener(_onAlertServiceChanged);
    _alertService.dispose();
    super.dispose();
  }
}