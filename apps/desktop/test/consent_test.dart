// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// Requirements: FR-PROF-001, FR-PROF-010
// Implemented here: tests for TC-FR-PROF-001-01 (privacy notice, version and timestamp) and TC-FR-PROF-010-01 (age policy outcome only, no date of birth)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/features/consent/consent_screen.dart';

void main() {
  group('TC-FR-PROF-001-01 Privacy notice presentation and consent recording', () {
    testWidgets('presents privacy notice version and disables agree button initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConsentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Displays privacy notice title and notice version
      expect(find.text('Privacy Notice'), findsOneWidget);
      expect(find.text('Version 1.0'), findsOneWidget);

      // Agree button is disabled until requirements are checked
      await tester.ensureVisible(find.byKey(const Key('consent_agree_button')));
      final agreeButton = tester.widget<FilledButton>(find.byKey(const Key('consent_agree_button')));
      expect(agreeButton.onPressed, isNull);
    });

    testWidgets('records consent with notice version and timestamp when student agrees', (WidgetTester tester) async {
      String? recordedVersion;
      String? recordedTimestamp;
      bool? recordedAgeCheck;
      bool legacyCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ConsentScreen(
            onConsent: ({
              required String noticeVersion,
              required String timestamp,
              required bool ageCheckPassed,
            }) {
              recordedVersion = noticeVersion;
              recordedTimestamp = timestamp;
              recordedAgeCheck = ageCheckPassed;
            },
            onConsentCallback: () {
              legacyCallbackCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure visible and tap both checkboxes
      await tester.ensureVisible(find.byKey(const Key('consent_age_checkbox')));
      await tester.tap(find.byKey(const Key('consent_age_checkbox')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('consent_privacy_checkbox')));
      await tester.tap(find.byKey(const Key('consent_privacy_checkbox')));
      await tester.pumpAndSettle();

      // Agree button is now enabled
      await tester.ensureVisible(find.byKey(const Key('consent_agree_button')));
      final agreeButton = tester.widget<FilledButton>(find.byKey(const Key('consent_agree_button')));
      expect(agreeButton.onPressed, isNotNull);

      // Tap Agree button
      await tester.tap(find.byKey(const Key('consent_agree_button')));
      await tester.pumpAndSettle();

      expect(recordedVersion, equals('1.0'));
      expect(recordedAgeCheck, isTrue);
      expect(recordedTimestamp, isNotNull);
      // Validate ISO8601 timestamp format
      expect(DateTime.tryParse(recordedTimestamp!), isNotNull);
      expect(legacyCallbackCalled, isTrue);
    });
  });

  group('TC-FR-PROF-010-01 Age policy verification with outcome only', () {
    testWidgets('applies age policy and contains NO date of birth collection fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConsentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Age policy disclosure is visible
      expect(find.text('Age Verification (TBD-08)'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('consent_age_checkbox')));
      expect(find.text('I confirm that I am at least 18 years old.'), findsOneWidget);

      // Verify STRICT absence of any Date of Birth text fields or date pickers
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Date of Birth', findRichText: true), findsNothing);
      expect(find.textContaining('dob', findRichText: true), findsNothing);
      expect(find.textContaining('birth date', findRichText: true), findsNothing);
    });

    testWidgets('declining consent shows required notice and invokes onDecline', (WidgetTester tester) async {
      bool declineInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ConsentScreen(
            onDecline: () {
              declineInvoked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Decline button
      await tester.ensureVisible(find.byKey(const Key('consent_decline_button')));
      await tester.tap(find.byKey(const Key('consent_decline_button')));
      await tester.pumpAndSettle();

      expect(declineInvoked, isTrue);
      expect(find.byKey(const Key('consent_decline_message')), findsOneWidget);
      expect(
        find.textContaining('Consent and age confirmation are required to use DevSphere'),
        findsOneWidget,
      );
    });
  });
}
