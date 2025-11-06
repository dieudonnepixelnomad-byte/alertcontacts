import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../../../core/models/contact_relation.dart';
import '../../../core/models/invitation.dart'; // Pour ShareLevel
import '../../../core/services/api_relationship_service.dart';
import '../../../core/providers/auth_aware_provider.dart';

class RelationshipProvider extends ChangeNotifier with AuthAwareProvider {
  final ApiRelationshipService _apiService = ApiRelationshipService();

  List<ContactRelation> _relationships = [];
  RelationStats? _stats;
  List<Contact> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // Getters
  List<ContactRelation> get relationships => _relationships;
  RelationStats? get stats => _stats;
  List<Contact> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  // Filtres
  List<ContactRelation> get acceptedRelationships => _relationships
      .where((rel) => rel.status == RelationStatus.accepted)
      .toList();

  List<ContactRelation> get pendingRelationships => _relationships
      .where((rel) => rel.status == RelationStatus.pending)
      .toList();

  List<ContactRelation> get refusedRelationships => _relationships
      .where((rel) => rel.status == RelationStatus.refused)
      .toList();

  List<ContactRelation> get realtimeContacts => _relationships
      .where(
        (rel) =>
            rel.status == RelationStatus.accepted &&
            rel.shareLevel == ShareLevel.realtime,
      )
      .toList();

  List<ContactRelation> get alertOnlyContacts => _relationships
      .where(
        (rel) =>
            rel.status == RelationStatus.accepted &&
            rel.shareLevel == ShareLevel.alertOnly,
      )
      .toList();

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

  /// Charger toutes les relations
  Future<void> loadRelationships() async {
    log('Chargement des relations...');

    _setLoading(true);
    _clearError();

    try {
      final relationships = await _apiService.getMyRelationships();
      _relationships = relationships;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des contacts: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Charger les statistiques
  Future<void> loadStats() async {
    try {
      final stats = await _apiService.getRelationshipStats();
      _stats = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des stats: $e');
    }
  }

  /// Obtenir une relation spécifique
  Future<ContactRelation?> getRelationship(String relationshipId) async {
    try {
      final relationship = await _apiService.getRelationship(relationshipId);

      // Mettre à jour la relation dans la liste locale
      final index = _relationships.indexWhere(
        (rel) => rel.id == relationshipId,
      );
      if (index != -1) {
        _relationships[index] = relationship;
        notifyListeners();
      }

      return relationship;
    } catch (e) {
      _setError('Erreur lors de la récupération du contact: ${e.toString()}');
      return null;
    }
  }

  /// Mettre à jour le niveau de partage
  Future<bool> updateShareLevel(
    String relationshipId,
    ShareLevel shareLevel,
  ) async {
    _clearError();

    try {
      final updatedRelation = await _apiService.updateShareLevel(
        relationshipId: relationshipId,
        shareLevel: shareLevel,
        canSeeMe: true, // Valeur par défaut, peut être paramétrable
      );

      // Mettre à jour la relation dans la liste locale
      final index = _relationships.indexWhere(
        (rel) => rel.id == relationshipId,
      );
      if (index != -1) {
        _relationships[index] = updatedRelation;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: ${e.toString()}');
      return false;
    }
  }

  /// Supprimer une relation
  Future<bool> deleteRelationship(String relationshipId) async {
    _clearError();

    try {
      await _apiService.deleteRelationship(relationshipId);
      _relationships.removeWhere((rel) => rel.id == relationshipId);
      notifyListeners();

      // Recharger les stats
      await loadStats();

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: ${e.toString()}');
      return false;
    }
  }

  /// Rechercher des utilisateurs
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _setSearching(true);
    _clearError();

    try {
      final results = await _apiService.searchUsers(query);
      _searchResults = results;
      _setSearching(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la recherche: ${e.toString()}');
      _setSearching(false);
    }
  }

  /// Nettoyer les résultats de recherche
  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  /// Rafraîchir toutes les données
  Future<void> refresh() async {
    await Future.wait([loadRelationships(), loadStats()]);
  }

  /// Obtenir une relation par ID de contact
  ContactRelation? getRelationshipByContactId(String contactId) {
    try {
      return _relationships.firstWhere((rel) => rel.contact.id == contactId);
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si un utilisateur est déjà un contact
  bool isAlreadyContact(String userId) {
    return _relationships.any((rel) => rel.contact.id == userId);
  }

  /// Obtenir le nombre de contacts par niveau de partage
  Map<ShareLevel, int> getShareLevelCounts() {
    final counts = <ShareLevel, int>{};

    for (final level in ShareLevel.values) {
      counts[level] = acceptedRelationships
          .where((rel) => rel.shareLevel == level)
          .length;
    }

    return counts;
  }

  /// Obtenir le nombre de relations par statut
  Map<RelationStatus, int> getStatusCounts() {
    final counts = <RelationStatus, int>{};

    for (final status in RelationStatus.values) {
      counts[status] = _relationships
          .where((rel) => rel.status == status)
          .length;
    }

    return counts;
  }

  /// Filtrer les relations par niveau de partage
  List<ContactRelation> getRelationshipsByShareLevel(ShareLevel shareLevel) {
    return acceptedRelationships
        .where((rel) => rel.shareLevel == shareLevel)
        .toList();
  }

  /// Filtrer les relations par statut
  List<ContactRelation> getRelationshipsByStatus(RelationStatus status) {
    return _relationships.where((rel) => rel.status == status).toList();
  }

  /// Obtenir les contacts qui peuvent voir ma position
  List<ContactRelation> getContactsWhoCanSeeMe() {
    return acceptedRelationships
        .where((rel) => rel.canSeeMe && rel.shareLevel != ShareLevel.none)
        .toList();
  }

  /// Nettoyer l'état
  void clear() {
    _relationships.clear();
    _searchResults.clear();
    _stats = null;
    _clearError();
    _setLoading(false);
    _setSearching(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
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
