import 'package:alertcontacts/core/services/api_routes_service.dart';
import 'package:alertcontacts/core/services/prefs_service.dart';
import 'package:alertcontacts/features/trajets/presentation/route_search_page.dart';
import 'package:alertcontacts/features/trajets/providers/route_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';

void main() {
  testWidgets('⇅ échange réellement le départ et l’arrivée avant validation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RouteProvider(ApiRoutesService(), PrefsService()),
        child: MaterialApp(
          home: RouteSearchPage(
            initialOrigin: const gmaps.LatLng(4.0511, 9.7679),
            initialOriginLabel: 'Douala',
            initialDestination: const gmaps.LatLng(3.8480, 11.5021),
            initialDestinationLabel: 'Yaoundé',
          ),
        ),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, 'Douala');
    expect(fields[1].controller!.text, 'Yaoundé');
    expect(
      tester.widget<IconButton>(find.byKey(const Key('route_search_swap_button'))).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('route_search_swap_button')));
    await tester.pump();

    final swappedFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(swappedFields[0].controller!.text, 'Yaoundé');
    expect(swappedFields[1].controller!.text, 'Douala');
    expect(find.text('Voir les itinéraires'), findsOneWidget);
  });
}
