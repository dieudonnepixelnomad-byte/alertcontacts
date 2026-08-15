import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Types d'incident communautaire — CDC V4.1 §4.9
///
/// Taxonomie unique, alignée sur `config/incidents.php` côté Laravel. Elle
/// remplace les deux taxonomies disjointes du V4.0 — `AlertType` (7 valeurs
/// anglaises) et `DangerType` (15 slugs français) — dont aucune correspondance
/// n'était codée, ce qui faisait retomber `aggression` et `suspicious_package`
/// sur « autre » à la lecture.
///
/// L'utilisateur ne voit jamais la table du §4.9 : gravité, géométrie, TTL et
/// rayons sont déduits côté serveur du type choisi.
enum IncidentType {
  accident('accident', 'Accident', '🚗'),
  fire('fire', 'Incendie', '🔥'),
  aggression('aggression', 'Agression', '⚠️'),
  suspect('suspect', 'Individu suspect', '👤'),
  suspiciousPackage('suspicious_package', 'Colis suspect', '📦'),
  roadworks('roadworks', 'Travaux', '🚧'),
  trafficJam('traffic_jam', 'Embouteillage', '🚦'),
  flood('flood', 'Inondation', '🌊'),
  protest('protest', 'Manifestation', '📢'),
  other('other', 'Autre', '🔔');

  const IncidentType(this.value, this.label, this.emoji);

  final String value;
  final String label;
  final String emoji;

  /// Correspondances depuis les valeurs V4.0, pour lire sans casse les
  /// réponses des anciens endpoints et les alertes reprises en base.
  static const Map<String, IncidentType> _legacyAliases = {
    'agression': IncidentType.aggression,
    'vol': IncidentType.aggression,
    'braquage': IncidentType.aggression,
    'harcelement': IncidentType.aggression,
    'accident_frequent': IncidentType.accident,
    'construction_dangereuse': IncidentType.roadworks,
    'manifestation': IncidentType.protest,
    'inondation': IncidentType.flood,
    'theft': IncidentType.aggression,
    'murder': IncidentType.aggression,
    'autre': IncidentType.other,
    'zone_non_eclairee': IncidentType.other,
    'zone_marecageuse': IncidentType.other,
    'deal_drogue': IncidentType.other,
    'vandalisme': IncidentType.other,
    'zone_deserte': IncidentType.other,
    'animaux_errants': IncidentType.other,
  };

  static IncidentType fromValue(String? value) {
    if (value == null) return IncidentType.other;

    for (final type in IncidentType.values) {
      if (type.value == value) return type;
    }

    return _legacyAliases[value] ?? IncidentType.other;
  }

  /// Types proposés dans le formulaire de signalement (§6.6), dans l'ordre
  /// d'affichage. « Autre » ferme la liste.
  static const List<IncidentType> reportable = [
    IncidentType.accident,
    IncidentType.fire,
    IncidentType.aggression,
    IncidentType.suspect,
    IncidentType.suspiciousPackage,
    IncidentType.trafficJam,
    IncidentType.roadworks,
    IncidentType.flood,
    IncidentType.protest,
    IncidentType.other,
  ];
}

/// Gravité — CDC V4.1 §4.1
///
/// Détermine **uniquement** couleur, priorité et tri. Rien d'autre : ni
/// l'étendue géométrique, ni la durée de vie, qui découlent du type.
enum IncidentSeverity {
  low('low', 'Faible'),
  medium('medium', 'Moyen'),
  high('high', 'Élevé');

  const IncidentSeverity(this.value, this.label);

  final String value;
  final String label;

  static IncidentSeverity fromValue(String? value) {
    return switch (value) {
      'low' => IncidentSeverity.low,
      'high' || 'critical' => IncidentSeverity.high,
      _ => IncidentSeverity.medium,
    };
  }

  Color get color => switch (this) {
        IncidentSeverity.low => AppColors.gravityLow,
        IncidentSeverity.medium => AppColors.gravityMid,
        IncidentSeverity.high => AppColors.gravityHigh,
      };

  String get emoji => switch (this) {
        IncidentSeverity.low => '🟡',
        IncidentSeverity.medium => '🟠',
        IncidentSeverity.high => '🔴',
      };

  /// Rang de tri — le plus grave en premier (§5.4 étape 3).
  int get rank => switch (this) {
        IncidentSeverity.high => 3,
        IncidentSeverity.medium => 2,
        IncidentSeverity.low => 1,
      };
}

/// Statut d'un incident — CDC V4.1 §4.7
enum IncidentStatus {
  active('active'),
  resolved('resolved'),
  expired('expired'),
  rejected('rejected');

  const IncidentStatus(this.value);

  final String value;

  static IncidentStatus fromValue(String? value) {
    for (final status in IncidentStatus.values) {
      if (status.value == value) return status;
    }
    return IncidentStatus.active;
  }

  bool get isLive => this == IncidentStatus.active;
}
