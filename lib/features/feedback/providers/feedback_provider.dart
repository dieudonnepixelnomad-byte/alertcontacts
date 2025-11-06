// lib/features/feedback/providers/feedback_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/repositories/feedback_repository.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository;
  
  bool _isLoading = false;
  String? _error;

  FeedbackProvider({required FeedbackRepository feedbackRepository})
      : _feedbackRepository = feedbackRepository;

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
      await _feedbackRepository.submitFeedback(
        category: category,
        subject: subject,
        message: message,
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