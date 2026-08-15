import 'package:alertcontacts/core/utils/flexible_polyline.dart';
import 'package:flutter_test/flutter_test.dart';

/// CDC V4.1 §14.1 point 4 — décodeur Flexible Polyline côté Dart.
///
/// Vecteurs issus de l'implémentation de référence heremaps/flexible-polyline.
/// Le pendant PHP est couvert par tests/Unit/FlexiblePolylineTest.php côté
/// backend : les deux implémentations doivent rester d'accord, sinon le tracé
/// affiché diverge de celui contre lequel les incidents ont été testés.
void main() {
  group('FlexiblePolyline.decode', () {
    test('décode le vecteur de référence HERE', () {
      final points = FlexiblePolyline.decode('BFoz5xJ67i1B1B7PzIhaxL7Y');

      expect(points, hasLength(4));
      expect(points[0], const PolylinePoint(50.10228, 8.69821));
      expect(points[1], const PolylinePoint(50.10201, 8.69567));
      expect(points[2], const PolylinePoint(50.10063, 8.69150));
      expect(points[3], const PolylinePoint(50.09878, 8.68752));
    });

    test('une chaîne vide donne une polyligne vide', () {
      expect(FlexiblePolyline.decode(''), isEmpty);
    });

    test('rejette un caractère invalide plutôt que de tracer un trajet faux', () {
      expect(
        () => FlexiblePolyline.decode('BFoz5xJ67i1B!!!'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejette une chaîne tronquée', () {
      expect(
        () => FlexiblePolyline.decode('B'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FlexiblePolyline.encode', () {
    test('aller-retour sans perte au-delà de la précision demandée', () {
      const original = [
        PolylinePoint(48.8566, 2.3522),
        PolylinePoint(48.8600, 2.3480),
        PolylinePoint(48.8738, 2.2950),
      ];

      final decoded = FlexiblePolyline.decode(FlexiblePolyline.encode(original));

      expect(decoded, hasLength(3));

      for (var i = 0; i < original.length; i++) {
        expect(decoded[i].lat, closeTo(original[i].lat, 0.0000001));
        expect(decoded[i].lng, closeTo(original[i].lng, 0.0000001));
      }
    });

    test('gère les coordonnées négatives', () {
      const original = [
        PolylinePoint(-33.8688, 151.2093),
        PolylinePoint(-34.0, -58.3816),
      ];

      final decoded = FlexiblePolyline.decode(FlexiblePolyline.encode(original));

      expect(decoded[0].lat, closeTo(-33.8688, 0.0000001));
      expect(decoded[1].lng, closeTo(-58.3816, 0.0000001));
    });

    test('une polyligne vide donne une chaîne vide', () {
      expect(FlexiblePolyline.encode(const []), isEmpty);
    });

    test('refuse une précision hors bornes', () {
      expect(
        () => FlexiblePolyline.encode(
          const [PolylinePoint(48.85, 2.35)],
          precision: 20,
        ),
        throwsArgumentError,
      );
    });
  });
}
