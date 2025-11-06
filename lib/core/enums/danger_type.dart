enum DangerType {
  agression('agression', 'Agression', '🔪'),
  vol('vol', 'Vol', '💰'),
  braquage('braquage', 'Braquage', '🔫'),
  harcelement('harcelement', 'Harcèlement', '👥'),
  zoneNonEclairee('zone_non_eclairee', 'Zone non éclairée', '🌙'),
  zoneMarecageuse('zone_marecageuse', 'Zone marécageuse', '🌊'),
  accidentFrequent('accident_frequent', 'Accidents fréquents', '🚗'),
  dealDrogue('deal_drogue', 'Deal de drogue', '💊'),
  vandalisme('vandalisme', 'Vandalisme', '🔨'),
  zoneDeserte('zone_deserte', 'Zone déserte', '🏜️'),
  constructionDangereuse(
    'construction_dangereuse',
    'Construction dangereuse',
    '🏗️',
  ),
  animauxErrants('animaux_errants', 'Animaux errants', '🐕'),
  manifestation('manifestation', 'Manifestation', '📢'),
  inondation('inondation', 'Risque d\'inondation', '🌊'),
  autre('autre', 'Autre', '⚠️');

  const DangerType(this.value, this.label, this.emoji);

  final String value;
  final String label;
  final String emoji;

  static DangerType fromValue(String value) {
    return DangerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DangerType.autre,
    );
  }

  String get displayName => '$emoji $label';

  /// Retourne la couleur associée au type de danger
  int get colorValue {
    switch (this) {
      case DangerType.agression:
      case DangerType.braquage:
      case DangerType.harcelement:
        return 0xFFD32F2F; // Rouge foncé
      case DangerType.vol:
      case DangerType.dealDrogue:
      case DangerType.vandalisme:
        return 0xFFE53935; // Rouge
      case DangerType.zoneNonEclairee:
      case DangerType.zoneDeserte:
        return 0xFF7B1FA2; // Violet
      case DangerType.zoneMarecageuse:
      case DangerType.inondation:
        return 0xFF1976D2; // Bleu
      case DangerType.accidentFrequent:
      case DangerType.constructionDangereuse:
        return 0xFFFF8F00; // Orange
      case DangerType.animauxErrants:
      case DangerType.manifestation:
        return 0xFFF57C00; // Orange foncé
      case DangerType.autre:
        return 0xFF616161; // Gris
    }
  }

  /// Retourne le niveau de priorité du type de danger (1-5)
  int get priorityLevel {
    switch (this) {
      case DangerType.agression:
      case DangerType.braquage:
        return 5; // Très élevé
      case DangerType.harcelement:
      case DangerType.dealDrogue:
        return 4; // Élevé
      case DangerType.vol:
      case DangerType.vandalisme:
      case DangerType.accidentFrequent:
        return 3; // Moyen
      case DangerType.zoneNonEclairee:
      case DangerType.zoneDeserte:
      case DangerType.constructionDangereuse:
        return 2; // Faible
      case DangerType.zoneMarecageuse:
      case DangerType.animauxErrants:
      case DangerType.manifestation:
      case DangerType.inondation:
        return 2; // Faible
      case DangerType.autre:
        return 1; // Très faible
    }
  }

  /// Retourne une description du type de danger
  String get description {
    switch (this) {
      case DangerType.agression:
        return 'Zone où des agressions ont été signalées';
      case DangerType.vol:
        return 'Zone à risque de vol ou pickpocket';
      case DangerType.braquage:
        return 'Zone où des braquages ont eu lieu';
      case DangerType.harcelement:
        return 'Zone où du harcèlement a été signalé';
      case DangerType.zoneNonEclairee:
        return 'Zone mal éclairée, risque accru la nuit';
      case DangerType.zoneMarecageuse:
        return 'Zone humide ou marécageuse, risque de chute';
      case DangerType.accidentFrequent:
        return 'Zone où des accidents sont fréquents';
      case DangerType.dealDrogue:
        return 'Zone de trafic de drogue';
      case DangerType.vandalisme:
        return 'Zone sujette au vandalisme';
      case DangerType.zoneDeserte:
        return 'Zone isolée, peu fréquentée';
      case DangerType.constructionDangereuse:
        return 'Construction en cours ou bâtiment dangereux';
      case DangerType.animauxErrants:
        return 'Présence d\'animaux errants ou dangereux';
      case DangerType.manifestation:
        return 'Zone de manifestation ou rassemblement';
      case DangerType.inondation:
        return 'Zone à risque d\'inondation';
      case DangerType.autre:
        return 'Autre type de danger';
    }
  }
}
