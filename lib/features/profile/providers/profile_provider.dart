import 'package:flutter/foundation.dart';
import '../../../core/models/user.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/providers/auth_aware_provider.dart';

class ProfileProvider extends ChangeNotifier with AuthAwareProvider {
  final ProfileRepository _profileRepository;
  
  bool _isLoading = false;
  String? _error;
  User? _user;

  ProfileProvider(this._profileRepository);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  /// Met à jour le profil utilisateur
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _profileRepository.updateProfile(
        name: name,
        photoUrl: photoUrl,
      );
      
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Exporte les données utilisateur (RGPD)
  Future<void> exportUserData() async {
    _setLoading(true);
    _clearError();

    try {
      await _profileRepository.exportUserData();
    } catch (e) {
      _setError('Erreur lors de l\'export des données: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprime le compte utilisateur (RGPD)
  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _profileRepository.deleteAccount();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression du compte: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour les consentements RGPD
  Future<void> updateConsents({
    bool? locationConsent,
    bool? notificationConsent,
    bool? analyticsConsent,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _profileRepository.updateConsents(
        locationConsent: locationConsent,
        notificationConsent: notificationConsent,
        analyticsConsent: analyticsConsent,
      );
    } catch (e) {
      _setError('Erreur lors de la mise à jour des consentements: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Demande la limitation du traitement des données (RGPD)
  Future<void> requestDataProcessingLimitation() async {
    _setLoading(true);
    _clearError();

    try {
      await _profileRepository.requestDataProcessingLimitation();
    } catch (e) {
      _setError('Erreur lors de la demande de limitation: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Charge le profil utilisateur
  Future<void> loadProfile() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _profileRepository.getProfile();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement du profil: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void onAuthTokenChanged(String? token) {
    // Le ProfileRepository récupère automatiquement le token depuis les préférences
    // Aucune action spécifique nécessaire ici
  }
}