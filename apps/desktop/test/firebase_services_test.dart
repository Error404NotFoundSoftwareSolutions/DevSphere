// User story: US-01 Sign in with Google (Sprint 1, MVP)
// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, FR-PROF-001, FR-PROF-010
// Tests for Firebase Authentication and Firestore data models and services

import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/features/auth/firebase_auth_service.dart';
import 'package:desktop/features/auth/sign_in_service.dart';
import 'package:desktop/features/firestore/firestore_service.dart';

void main() {
  group('Firebase Services & Models (TC-FR-AUTH-001 & TC-FR-PROF-010)', () {
    test('StudentConsentRecord serializes notice version and age check outcome without date of birth', () {
      const record = StudentConsentRecord(
        noticeVersion: '1.0',
        timestamp: '2026-11-05T00:00:00Z',
        ageCheckPassed: true,
      );

      final map = record.toFirestore();
      expect(map['noticeVersion'], equals('1.0'));
      expect(map['timestamp'], equals('2026-11-05T00:00:00Z'));
      expect(map['ageCheckPassed'], isTrue);

      // TC-FR-PROF-010-01: strictly NO date of birth
      expect(map.containsKey('dateOfBirth'), isFalse);
      expect(map.containsKey('dob'), isFalse);
      expect(map.containsKey('birthDate'), isFalse);
    });

    test('StudentProfile converts to and from map with correct fields', () {
      const profile = StudentProfile(
        uid: 'user-123',
        displayName: 'Alice Student',
        email: 'alice@example.com',
        college: 'Engineering College',
        course: 'Computer Science',
        interests: ['Python', 'Cloud'],
      );

      final map = profile.toFirestore();
      expect(map['displayName'], equals('Alice Student'));
      expect(map['email'], equals('alice@example.com'));
      expect(map['college'], equals('Engineering College'));
      expect(map['course'], equals('Computer Science'));
      expect(map['interests'], equals(['Python', 'Cloud']));
    });

    test('FirebaseAuthService handles and classifies authentication exceptions', () {
      final authService = FirebaseAuthService();
      expect(authService, isNotNull);

      final signInService = SignInService();
      final cancelledError = signInService.classifyError(Exception('User cancelled the popup'));
      expect(cancelledError.type, equals(AuthErrorType.cancelled));

      final networkError = signInService.classifyError(Exception('Network socket error'));
      expect(networkError.type, equals(AuthErrorType.networkFailure));
    });
  });
}

