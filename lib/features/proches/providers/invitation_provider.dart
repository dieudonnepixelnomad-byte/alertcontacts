import 'package:flutter/foundation.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/api_invitation_service.dart';
import '../../../core/providers/auth_aware_provider.dart';

class InvitationProvider extends ChangeNotifier with AuthAwareProvider {
  final ApiInvitationService _apiService = ApiInvitationService();
  
  List<Invitation> _invitations = [];
  bool _isLoading = false;
  String? _error;
  Invitation? _currentInvitation;

  // Getters
  List<Invitation> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Invitation? get currentInvitation => _currentInvitation;

  // Filtres
  List<Invitation> get activeInvitations => 
      _invitations.where((inv) => inv.isValid).toList();

  List<Invitation> get expiredInvitations => 
      _invitations.where((inv) => inv.isExpired).toList();

  List<Invitation> get acceptedInvitations => 
      _invitations.where((inv) => inv.status == InvitationStatus.accepted).toList();

  List<Invitation> get pendingInvitations => 
      _invitations.where((inv) => inv.status == InvitationStatus.pending).toList();

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  @override
  void onAuthTokenChanged(String? token) {
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }

  /// Initialiser le provider avec l'authentification
  Future<void> initialize() async {
    await initializeAuth();
  }

  /// Créer une nouvelle invitation
  Future<Invitation?> createInvitation({
    required ShareLevel defaultShareLevel,
    List<String>? suggestedZones,
    int? expiresInHours,
    int? maxUses,
    bool? requirePin,
    String? message,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final invitation = await _apiService.createInvitation(
        defaultShareLevel: defaultShareLevel,
        suggestedZones: suggestedZones,
        expiresInHours: expiresInHours,
        maxUses: maxUses,
        requirePin: requirePin,
        message: message,
      );

      _invitations.insert(0, invitation);
      _setLoading(false);
      notifyListeners();
      
      return invitation;
    } catch (e) {
      _setError('Erreur lors de la création de l\'invitation: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Vérifier une invitation par token
  Future<Invitation?> checkInvitation(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final invitation = await _apiService.checkInvitation(token);
      _currentInvitation = invitation;
      _setLoading(false);
      notifyListeners();
      
      return invitation;
    } catch (e) {
      _setError('Erreur lors de la vérification: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Accepter une invitation
  Future<bool> acceptInvitation({
    required String token,
    String? pin,
    required ShareLevel shareLevel,
    List<String>? acceptedZones,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.acceptInvitation(
        token: token,
        shareLevel: shareLevel,
        acceptedZones: acceptedZones ?? [],
        pin: pin,
      );

      _setLoading(false);
      _currentInvitation = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'acceptation: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Charger toutes les invitations de l'utilisateur
  Future<void> loadMyInvitations() async {
    _setLoading(true);
    _clearError();

    try {
      final invitations = await _apiService.getMyInvitations();
      _invitations = invitations;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Supprimer une invitation
  Future<bool> deleteInvitation(String invitationId) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.deleteInvitation(invitationId);
      _invitations.removeWhere((inv) => inv.id == invitationId);
      _setLoading(false);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Rafraîchir les invitations
  Future<void> refresh() async {
    await loadMyInvitations();
  }

  /// Nettoyer les invitations expirées localement
  void cleanExpiredInvitations() {
    final initialCount = _invitations.length;
    _invitations.removeWhere((inv) => inv.isExpired);
    
    if (_invitations.length != initialCount) {
      notifyListeners();
    }
  }

  /// Obtenir une invitation par ID
  Invitation? getInvitationById(String id) {
    try {
      return _invitations.firstWhere((inv) => inv.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir une invitation par token
  Invitation? getInvitationByToken(String token) {
    try {
      return _invitations.firstWhere((inv) => inv.token == token);
    } catch (e) {
      return null;
    }
  }

  /// Compter les invitations par statut
  Map<InvitationStatus, int> getInvitationCounts() {
    final counts = <InvitationStatus, int>{};
    
    for (final status in InvitationStatus.values) {
      counts[status] = _invitations.where((inv) => inv.status == status).length;
    }
    
    return counts;
  }

  /// Nettoyer l'état
  void clear() {
    _invitations.clear();
    _currentInvitation = null;
    _clearError();
    _setLoading(false);
    notifyListeners();
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
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}