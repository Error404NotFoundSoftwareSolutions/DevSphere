// User story: US-16 Native desktop shell startup and baseline performance (Sprint 4, MVP)
// Requirements: NFR-PERF-001, NFR-PORT-001
// Test ID: TC-NFR-PERF-001-01
// Implemented here: Smoke test ensuring the BuildLoop desktop app launches cleanly

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/app.dart';

void main() {
  testWidgets('BuildLoop desktop shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: BuildLoopApp()));
    await tester.pumpAndSettle();

    expect(find.text('Devpilot'), findsWidgets);
    expect(find.text('Learn by building.'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });
}
