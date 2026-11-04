import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_lab/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskManagementApp());

    // Verify app title or core elements exist
    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
