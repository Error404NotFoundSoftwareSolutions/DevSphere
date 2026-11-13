// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: TC-FR-EXEC-002-02: shell characters in arguments stay plain text

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:local_worker/src/exec/safe_spawn.dart';

void main() {
  group('TC-FR-EXEC-002-02 no shell interpretation', () {
    test('treats metacharacters as literal text', () async {
      final dir = Directory.systemTemp.createTempSync('ds-');
      addTearDown(() => dir.deleteSync(recursive: true));

      final pwnedFile = p.join(dir.path, 'pwned');
      final evil = 'hi; touch $pwnedFile';

      final r = await runProcess(
        'python3',
        ['-c', 'import sys; print(sys.argv[1])', evil],
        cwd: dir.path,
        timeout: const Duration(seconds: 10),
      );

      expect(r.output, contains('hi;'));
      // Verify that the evil command was not executed
      expect(File(pwnedFile).existsSync(), isFalse);
    });

    test('rejects a folder outside the workspace', () {
      final dir = Directory.systemTemp.createTempSync('ds-');
      addTearDown(() => dir.deleteSync(recursive: true));

      expect(() => resolveInside(dir.path, '..'), throwsArgumentError);
    });
  });

  test('TC-FR-EXEC-002-03 very short output is not lost when the program exits at once', () async {
    if (Platform.isWindows) return;
    for (var i = 0; i < 25; i++) {
      final r = await runProcess('echo', ['hi'], cwd: Directory.systemTemp.path, timeout: const Duration(seconds: 10));
      expect(r.output.trim(), 'hi', reason: 'run $i');
    }
  });
}
