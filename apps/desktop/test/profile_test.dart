// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-PROF-002, FR-PROF-003, FR-PROF-007, FR-PROF-008
// Implemented here: tests for TC-FR-PROF-002-01, TC-FR-PROF-003-01, TC-FR-PROF-007-01, and TC-FR-PROF-008-01

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/features/firestore/firestore_service.dart';
import 'package:desktop/features/profile/profile_screen.dart';

void main() {
  group('TC-FR-PROF-002-01 Display Name collection, prefilled and editable',
      () {
    testWidgets(
        'prefills display name from provider, is editable, and other fields are optional',
        (WidgetTester tester) async {
      StudentProfile? savedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
            initialDisplayName: 'Google Student Name',
            onSave: (profile) {
              savedProfile = profile;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify display name is prefilled
      final displayNameFinder =
          find.byKey(const Key('profile_display_name_field'));
      expect(displayNameFinder, findsOneWidget);
      expect(find.text('Google Student Name'), findsOneWidget);

      // 2. Edit display name
      await tester.enterText(displayNameFinder, 'Asha Edited');
      await tester.pumpAndSettle();
      expect(find.text('Asha Edited'), findsOneWidget);

      // 3. Save with all other fields blank (all other fields are optional per FR-PROF-002)
      final saveButtonFinder = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveButtonFinder);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(savedProfile, isNotNull);
      expect(savedProfile!.displayName, equals('Asha Edited'));
      expect(savedProfile!.college, isNull);
      expect(savedProfile!.course, isNull);
      expect(savedProfile!.academicYear, isNull);
      expect(savedProfile!.interests, isEmpty);
    });

    testWidgets(
        'rejects empty display name with field-level validation message',
        (WidgetTester tester) async {
      StudentProfile? savedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
            initialDisplayName: '',
            onSave: (profile) {
              savedProfile = profile;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveButtonFinder = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveButtonFinder);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Display name validation error shown
      expect(find.text('Display name is required.'), findsOneWidget);
      // onSave was not called
      expect(savedProfile, isNull);
    });
  });

  group(
      'TC-FR-PROF-003-01 Inspection: Profile fields supported and prohibited fields excluded',
      () {
    testWidgets(
        'supports optional college, course, academic year, interests; strictly NO DOB, phone, address',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Supported fields are present
      expect(
          find.byKey(const Key('profile_display_name_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_college_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_course_field')), findsOneWidget);
      expect(
          find.byKey(const Key('profile_academic_year_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_interests_field')), findsOneWidget);

      // Prohibited fields are strictly ABSENT (FR-PROF-003: no date of birth, phone number or address)
      expect(find.textContaining('Date of Birth', findRichText: true),
          findsNothing);
      expect(find.textContaining('dob', findRichText: true), findsNothing);
      expect(
          find.textContaining('birth date', findRichText: true), findsNothing);
      expect(find.textContaining('Phone', findRichText: true), findsNothing);
      expect(find.textContaining('Mobile', findRichText: true), findsNothing);
      expect(find.textContaining('Address', findRichText: true), findsNothing);
      expect(find.textContaining('Postal', findRichText: true), findsNothing);
      expect(find.textContaining('Zip', findRichText: true), findsNothing);
    });
  });

  group('TC-FR-PROF-007-01 Privacy notice presentation', () {
    testWidgets(
        'shows privacy disclosure stating profile data is private by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Profile data is private by default and visible only to you.'),
          findsOneWidget);
    });
  });

  group('TC-FR-PROF-008-01 View and edit profile after onboarding', () {
    testWidgets('renders existing profile values and saves modified updates',
        (WidgetTester tester) async {
      StudentProfile? updatedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
            initialDisplayName: 'Initial Student',
            initialCollege: 'PES University',
            initialCourse: 'B.Tech CS',
            initialAcademicYear: '3rd Year / 6th Sem',
            initialInterests: const ['Algorithms', 'Python'],
            isOnboarding: false,
            onSave: (profile) {
              updatedProfile = profile;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial fields are loaded into form
      expect(find.text('Initial Student'), findsOneWidget);
      expect(find.text('PES University'), findsOneWidget);
      expect(find.text('B.Tech CS'), findsOneWidget);
      expect(find.text('3rd Year / 6th Sem'), findsOneWidget);
      expect(find.text('Algorithms, Python'), findsOneWidget);

      // Edit fields
      final collegeFinder = find.byKey(const Key('profile_college_field'));
      await tester.enterText(collegeFinder, 'PES University Ring Road Campus');

      final interestsFinder = find.byKey(const Key('profile_interests_field'));
      await tester.enterText(interestsFinder, 'Python, Machine Learning, Go');

      await tester.pumpAndSettle();

      // Click save button
      final saveButtonFinder = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveButtonFinder);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(updatedProfile, isNotNull);
      expect(updatedProfile!.displayName, equals('Initial Student'));
      expect(
          updatedProfile!.college, equals('PES University Ring Road Campus'));
      expect(updatedProfile!.course, equals('B.Tech CS'));
      expect(updatedProfile!.academicYear, equals('3rd Year / 6th Sem'));
      expect(updatedProfile!.interests,
          equals(['Python', 'Machine Learning', 'Go']));
      expect(find.text('Profile saved successfully.'), findsOneWidget);
    });

    testWidgets('backward navigation buttons exist on profile screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            uid: 'student-123',
            email: 'student@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_back_button')), findsOneWidget);
      expect(
          find.byKey(const Key('profile_cancel_back_button')), findsOneWidget);
    });
  });
}
