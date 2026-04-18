// Basic smoke test – just verifies the app boots without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:uds/main.dart';

void main() {
  testWidgets('App boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RapsApp());
    // If we reach here the widget tree built successfully
    expect(find.text('RAPS SERVICE TOOL'), findsOneWidget);
  });
}
