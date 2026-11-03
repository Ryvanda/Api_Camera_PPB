import 'package:flutter_test/flutter_test.dart';

import 'package:camera_api/main.dart';

void main() {
  testWidgets('App renders HomeScreen with Open Camera action',
      (WidgetTester tester) async {
    // Build the CameraApiApp widget tree.
    await tester.pumpWidget(const CameraApiApp());
    await tester.pumpAndSettle();

    // Verify AppBar title is present.
    expect(find.text('Flutter Camera API'), findsOneWidget);

    // Verify Open Camera action button is present.
    expect(find.text('Open Camera'), findsOneWidget);

    // Verify empty state placeholder is present.
    expect(find.text('No photo captured yet'), findsOneWidget);
  });
}
