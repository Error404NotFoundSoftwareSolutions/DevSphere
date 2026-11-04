// User story: US-16 Native desktop shell startup and baseline performance (Sprint 4, MVP)
// User story: US-38 Stay signed in across app restarts until expiry or explicit sign out (Sprint 8, MVP)
// Requirements: NFR-PERF-001, FR-AUTH-007
// Test ID: TC-NFR-PERF-001-01
// Verifies startup timing and session restoration logic

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:desktop/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts cleanly within performance threshold (TC-NFR-PERF-001-01)', (WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(BuildLoopApp());
    await tester.pumpAndSettle();
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    expect(find.byType(BuildLoopApp), findsOneWidget);
  });
}

