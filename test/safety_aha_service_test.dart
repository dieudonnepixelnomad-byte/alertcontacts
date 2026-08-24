import 'package:alertcontacts/core/models/contact_location.dart';
import 'package:alertcontacts/core/models/safe_zone.dart';
import 'package:alertcontacts/core/services/safety_aha_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 24, 10);
  final service = SafetyAhaService();
  final zone = SafeZone(
    id: 'home',
    name: 'Maison',
    iconKey: 'home',
    center: const LatLng(3.866, 11.517),
    radiusMeters: 150,
    memberIds: const ['parent-1'],
  );

  ContactLocation location({
    DateTime? capturedAt,
    double accuracy = 15,
    double latitude = 3.866,
    double longitude = 11.517,
  }) => ContactLocation(
    id: 1,
    userId: 'parent-1',
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    capturedAtDevice: capturedAt ?? now.subtract(const Duration(minutes: 2)),
    createdAt: now,
    source: 'gps',
    foreground: false,
  );

  test('confirme seulement un proche affecté, présent et localisé récemment', () {
    final presence = service.findConfirmedPresence(
      contactId: 'parent-1',
      latestLocation: location(),
      zones: [zone],
      now: now,
    );

    expect(presence?.zone.id, 'home');
  });

  test('refuse une position ancienne, imprécise ou hors zone', () {
    expect(
      service.findConfirmedPresence(
        contactId: 'parent-1',
        latestLocation: location(capturedAt: now.subtract(const Duration(minutes: 11))),
        zones: [zone],
        now: now,
      ),
      isNull,
    );
    expect(
      service.findConfirmedPresence(
        contactId: 'parent-1',
        latestLocation: location(accuracy: 101),
        zones: [zone],
        now: now,
      ),
      isNull,
    );
    expect(
      service.findConfirmedPresence(
        contactId: 'parent-1',
        latestLocation: location(latitude: 3.9, longitude: 11.517),
        zones: [zone],
        now: now,
      ),
      isNull,
    );
  });
}
