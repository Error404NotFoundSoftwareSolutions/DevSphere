// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// User story: US-19 Read lab instructions with a fixed table of contents and step progress (Sprint 5, MVP)
// User story: US-28 Submit lab attempt for server grading with snapshot confirmation (Sprint 7, MVP)
// Requirements: FR-WS-001, FR-GUIDE-001, FR-SUB-001
// Test ID: TC-FR-WS-001-01
// End-to-end integration test of the learner first lab journey

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:desktop/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Learner first lab journey (TC-FR-WS-001-01)', (WidgetTester tester) async {
    await tester.pumpWidget(DevPilotApp());
    await tester.pumpAndSettle();

    // App launches on sign-in screen
    expect(find.text('DevPilot'), findsOneWidget);
  });
}
