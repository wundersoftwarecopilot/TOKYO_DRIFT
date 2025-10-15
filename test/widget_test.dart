// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:drift_admin/main.dart';

void main() {
  testWidgets('Drift Admin App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DriftAdminApp());

    // Verify that the app loads with the correct title (should be at least one)
    expect(find.text('TOKYO DRIFT'), findsWidgets);

    // Verify that the open database button is present
    expect(find.text('Open Database'), findsOneWidget);

    // Verify that navigation rail is present
    expect(find.text('Explorer'), findsOneWidget);
  });
}
