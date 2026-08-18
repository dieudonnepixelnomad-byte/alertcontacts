import '../enums/incident_type.dart';
import 'incident.dart';

/// Un signalement créé par le compte connecté, avec son incident agrégé.
class MyCommunityReport {
  const MyCommunityReport({
    required this.id,
    required this.type,
    required this.severity,
    required this.createdAt,
    this.comment,
    this.incident,
  });

  final int id;
  final IncidentType type;
  final IncidentSeverity severity;
  final DateTime createdAt;
  final String? comment;
  final Incident? incident;

  factory MyCommunityReport.fromJson(Map<String, dynamic> json) {
    final rawIncident = json['incident'];
    return MyCommunityReport(
      id: (json['id'] as num).toInt(),
      type: IncidentType.fromValue(json['type'] as String?),
      severity: IncidentSeverity.fromValue(json['severity'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      comment: json['comment'] as String?,
      incident: rawIncident is Map<String, dynamic>
          ? Incident.fromJson(rawIncident)
          : null,
    );
  }
}
