// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: TC-FR-GRADE-004-02: .env and key files are excluded by default

import 'package:test/test.dart';
import 'package:local_worker/src/snapshot/build_snapshot.dart';

void main() {
  group('TC-FR-GRADE-004-02 snapshot contents', () {
    test('excludes secret-bearing and ignored paths', () {
      final r = selectFiles([
        'app.py',
        '.env',
        '.env.local',
        'keys/server.pem',
        '.git/config',
        'src/id_rsa',
        'tests/test_app.py',
      ]);
      expect(r.files, equals(['app.py', 'tests/test_app.py']));
      expect(r.excluded.length, equals(5));
    });
  });
}
