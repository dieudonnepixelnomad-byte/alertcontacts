/// Énumération des fonctionnalités premium disponibles dans l'application
enum PremiumFeature {
  /// Zones illimitées & sur mesure
  /// Protection de tous les lieux importants (maison, école, travail, trajets)
  unlimitedZones('unlimited_zones'),
  
  /// Surveillance multi-proches
  /// Gestion centralisée de plusieurs contacts et de leurs zones
  multiContacts('multi_contacts'),
  
  /// Historique & rapports détaillés
  /// Accès aux alertes passées, mouvements et statistiques de sécurité
  detailedHistory('detailed_history');

  const PremiumFeature(this.id);

  /// Identifiant unique de la fonctionnalité
  final String id;

  /// Retourne la description de la fonctionnalité
  String get description {
    switch (this) {
      case PremiumFeature.unlimitedZones:
        return 'Protection de tous les lieux importants (maison, école, travail, trajets)';
      case PremiumFeature.multiContacts:
        return 'Gestion centralisée de plusieurs contacts et de leurs zones';
      case PremiumFeature.detailedHistory:
        return 'Accès aux alertes passées, mouvements et statistiques de sécurité';
    }
  }

  /// Retourne le titre de la fonctionnalité
  String get title {
    switch (this) {
      case PremiumFeature.unlimitedZones:
        return 'Zones illimitées & sur mesure';
      case PremiumFeature.multiContacts:
        return 'Surveillance multi-proches';
      case PremiumFeature.detailedHistory:
        return 'Historique & rapports détaillés';
    }
  }

  /// Retourne toutes les fonctionnalités premium
  static List<PremiumFeature> get all => PremiumFeature.values;

  /// Trouve une fonctionnalité par son ID
  static PremiumFeature? fromId(String id) {
    try {
      return PremiumFeature.values.firstWhere((feature) => feature.id == id);
    } catch (e) {
      return null;
    }
  }
}