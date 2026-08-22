import 'package:alertcontacts/features/paywall/presentation/paywall_compare_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('affiche uniquement les plans Free et Premium', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaywallComparePage()),
    );

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.textContaining('essai gratuit'), findsNothing);
    expect(find.textContaining('Family'), findsNothing);
  });
}
