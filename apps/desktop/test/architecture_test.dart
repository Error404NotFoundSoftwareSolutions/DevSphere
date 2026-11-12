// User story: US-14 Secure client runtime architecture (Sprint 4, MVP)
// Requirements: NFR-SEC-002, NFR-SEC-003
// Test ID: TC-NFR-SEC-002-01
// Verifies that apps/desktop/lib/ui and apps/desktop/lib/features never import dart:io or use Process/File APIs

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture security constraints (TC-NFR-SEC-002-01)', () {
    test(
        'UI and feature code must never import dart:io or access privileged File/Process APIs',
        () {
      final baseDir = Directory.current.path.endsWith('desktop')
          ? Directory.current
          : Directory('apps/desktop');

      final violations = <String>[];
      final targetDirs = [
        Directory('${baseDir.path}/lib/ui'),
        Directory('${baseDir.path}/lib/features'),
      ];

      for (final dir in targetDirs) {
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final content = entity.readAsStringSync();
            final lines = content.split('\n');
            for (var i = 0; i < lines.length; i++) {
              final line = lines[i];
              // Check for dart:io import
              if (line.contains("import 'dart:io'") ||
                  line.contains('import "dart:io"')) {
                violations
                    .add('${entity.path}:${i + 1} imports dart:io directly');
              }
              // Check for Process.run or Process.start references
              if (line.contains('Process.run') ||
                  line.contains('Process.start')) {
                violations.add('${entity.path}:${i + 1} accesses Process API');
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'UI layer must use typed IPC to local-worker instead of direct dart:io:\n${violations.join('\n')}',
      );
    });
  });
}
