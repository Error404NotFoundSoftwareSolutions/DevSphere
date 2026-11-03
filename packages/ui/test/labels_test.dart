// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// Implemented here: TC-FR-GRADE-002-01: Result and status label tests

import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  group('TC-FR-GRADE-002-01 result labels', () {
    test('labels practice results as unverified', () {
      expect(resultLabel(ResultKind.practice), equals('Practice (unverified)'));
    });

    test('labels verified results', () {
      expect(resultLabel(ResultKind.verified), equals('Verified'));
    });

    test('labels statuses properly capitalized', () {
      expect(statusLabel(StatusKind.ready), equals('Ready'));
      expect(statusLabel(StatusKind.missing), equals('Missing'));
    });
  });
}

