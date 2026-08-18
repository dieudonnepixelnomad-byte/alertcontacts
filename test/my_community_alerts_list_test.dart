import 'package:alertcontacts/core/enums/incident_type.dart';
import 'package:alertcontacts/core/models/incident.dart';
import 'package:alertcontacts/core/models/my_community_report.dart';
import 'package:alertcontacts/features/alertes/presentation/my_community_alerts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('affiche les alertes communautaires créées par le compte',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyCommunityAlertsList(
            reports: [
              MyCommunityReport(
                id: 1,
                type: IncidentType.fire,
                severity: IncidentSeverity.high,
                createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
                comment: 'Fumée visible près du carrefour.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Incendie signalé'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Fumée visible près du carrefour.'), findsOneWidget);
    expect(find.byKey(const Key('delete_my_alert_1')), findsOneWidget);
  });

  testWidgets('indique explicitement l’expiration au créateur',
      (WidgetTester tester) async {
    final expiry = DateTime(2026, 8, 18, 10, 30);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyCommunityAlertsList(
            reports: [
              MyCommunityReport(
                id: 2,
                type: IncidentType.trafficJam,
                severity: IncidentSeverity.low,
                createdAt: expiry.subtract(const Duration(minutes: 30)),
                incident: Incident(
                  id: 8,
                  type: IncidentType.trafficJam,
                  severity: IncidentSeverity.low,
                  lat: 4.0511,
                  lng: 9.7679,
                  displayRadiusM: 200,
                  reportCount: 1,
                  confirmCount: 0,
                  clearCount: 0,
                  confidenceScore: 0.25,
                  affectsRouting: false,
                  status: IncidentStatus.rejected,
                  expiredByTimeout: true,
                  expiresAt: expiry,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Expirée'), findsOneWidget);
    expect(find.textContaining('Cette alerte a expiré le'), findsOneWidget);
  });
}
