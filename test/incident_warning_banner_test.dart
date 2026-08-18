import 'package:alertcontacts/core/enums/incident_type.dart';
import 'package:alertcontacts/core/models/incident.dart';
import 'package:alertcontacts/core/models/route_plan.dart';
import 'package:alertcontacts/features/trajets/presentation/widgets/incident_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final incident = Incident(
    id: 42,
    type: IncidentType.fire,
    severity: IncidentSeverity.high,
    lat: 4.0511,
    lng: 9.7679,
    displayRadiusM: 200,
    reportCount: 2,
    confirmCount: 0,
    clearCount: 0,
    confidenceScore: 0.8,
    affectsRouting: true,
    status: IncidentStatus.active,
  );
  final hit = RouteIncidentHit(
    incident: incident,
    minDistanceM: 75,
    distanceFromOriginM: 1200,
    headline: '🔴 Incendie signalé sur ton trajet',
    detail: 'Signalé par 2 personnes',
  );

  test('une alerte active expirée n’est plus considérée comme visible', () {
    final expiredIncident = Incident(
      id: 43,
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
      status: IncidentStatus.active,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );

    expect(expiredIncident.isExpired, isTrue);
    expect(expiredIncident.isLive, isFalse);
  });

  testWidgets('affiche le bandeau et ses deux choix avant le départ',
      (WidgetTester tester) async {
    var avoidTapped = false;
    var continueTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentWarningBanner(
            hit: hit,
            onAvoid: () => avoidTapped = true,
            onContinue: () => continueTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('🔴 Incendie signalé sur ton trajet'), findsOneWidget);
    expect(find.text('Contourner'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);

    await tester.tap(find.text('Contourner'));
    await tester.tap(find.text('Continuer'));

    expect(avoidTapped, isTrue);
    expect(continueTapped, isTrue);
  });

  testWidgets('une alerte informative reste visible sans option de contournement',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentWarningBanner(
            hit: hit,
            canAvoid: false,
            onAvoid: () {},
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.text('🔴 Incendie signalé sur ton trajet'), findsOneWidget);
    expect(find.text('Contourner'), findsNothing);
    expect(find.text('Continuer'), findsOneWidget);
  });
}
