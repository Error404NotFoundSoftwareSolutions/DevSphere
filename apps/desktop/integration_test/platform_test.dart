// User story: US-R3-7 Cross-platform packaging and installer validation (Sprint 15, R3)
// Requirements: NFR-PORT-001, NFR-PORT-004
// Test ID: TC-NFR-PORT-001-01
// Cross-platform parity test across Windows, Linux, and macOS

import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:desktop/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Platform runtime environment is recognized (TC-NFR-PORT-001-01)', (WidgetTester tester) async {
    final isSupportedOS = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    expect(isSupportedOS, isTrue);

    await tester.pumpWidget(const DevSphereApp());
    await tester.pumpAndSettle();
    expect(find.byType(DevSphereApp), findsOneWidget);
  });
}

