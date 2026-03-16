// lib/features/feedback/providers/feedback_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/repositories/feedback_repository.dart';
import '../../../core/services/device_info_service.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository;
  final DeviceInfoService _deviceInfoService;

  bool _isLoading = false;
  String? _error;

  FeedbackProvider({
    required FeedbackRepository feedbackRepository,
    required DeviceInfoService deviceInfoService,
  })  : _feedbackRepository = feedbackRepository,
        _deviceInfoService = deviceInfoService;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Soumet un feedback
  Future<void> submitFeedback({
    required String category,
    required String subject,
    required String message,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final deviceInfo = await _deviceInfoService.getDeviceAndAppInfo();
      final appVersion = deviceInfo['appVersion'];
      final osVersion = deviceInfo['osVersion'];

      await _feedbackRepository.submitFeedback(
        category: category,
        subject: subject,
        message: message,
        appVersion: appVersion,
        osVersion: osVersion,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }
}