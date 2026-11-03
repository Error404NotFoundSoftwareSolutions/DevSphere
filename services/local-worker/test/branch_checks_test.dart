// User story: US-R3-2 Safe branch and remote checks (Sprint 13, R3)
// Requirements: FR-GIT-006..009, FR-CAT-011
// Implemented here: TC-FR-GIT-007-01: branch name validation

import 'package:test/test.dart';
import 'package:local_worker/src/git/branch_checks.dart';

void main() {
  group('TC-FR-GIT-007-01 branch names', () {
    test('accepts normal names', () {
      expect(isSafeBranchName('feature/fix-login'), isTrue);
    });

    test('rejects option-like and odd names', () {
      for (final bad in ['--upload-pack=evil', 'a..b', 'has space', 'x;rm']) {
        expect(isSafeBranchName(bad), isFalse, reason: 'Should reject: $bad');
      }
    });
  });
}

