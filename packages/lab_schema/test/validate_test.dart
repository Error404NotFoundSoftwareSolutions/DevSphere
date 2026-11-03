// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
// Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
// Implemented here: TC-FR-CAT-002-01: manifest validation tests

import 'dart:io';
import 'package:test/test.dart';
import 'package:lab_schema/lab_schema.dart';

void main() {
  group('TC-FR-CAT-002-01 manifest validation', () {
    late String schemaContent;

    setUpAll(() {
      schemaContent = File('manifest.schema.json').readAsStringSync();
    });

    final good = {
      'schema_version': 1,
      'id': 'python-hello-001',
      'version': '1.0.0',
      'title': 'Hello, Python',
      'difficulty': 'beginner',
      'os': ['windows', 'linux', 'macos'],
      'runtimes': [
        {'name': 'python', 'version': '>=3.12'}
      ],
      'workspace': {'type': 'code-editor', 'language': 'python'},
      'guide': {
        'steps': [
          {'id': 's1', 'title': 'Start', 'content_ref': 'guide/01.md'}
        ]
      },
      'tutor': {'enabled': true, 'max_assistance_level': 4},
      'evaluation': {
        'rubric_version': 1,
        'evaluator': 'pytest',
        'max_points': 100,
        'checks': [
          {'id': 'a', 'type': 'test', 'points': 100, 'visible': false}
        ],
      },
    };

    test('accepts a good manifest', () {
      final res = validateManifest(good, schemaContent: schemaContent);
      expect(res.ok, isTrue, reason: res.errors.join('; '));
    });

    test('rejects a missing title', () {
      final bad = Map<String, dynamic>.from(good)..remove('title');
      final res = validateManifest(bad, schemaContent: schemaContent);
      expect(res.ok, isFalse);
    });

    test('TC-FR-CAT-003-01 explains an unsupported schema version', () {
      final bad = Map<String, dynamic>.from(good)..['schema_version'] = 2;
      final res = validateManifest(bad, schemaContent: schemaContent);
      expect(res.ok, isFalse);
      expect(res.errors.first, contains('schema_version 2'));
    });

    test('checks that points add up', () {
      expect(checkPointsTotal(good), isTrue);
      final badPoints = {
        'evaluation': {
          'max_points': 100,
          'checks': [
            {'points': 30},
            {'points': 30},
          ],
        },
      };
      expect(checkPointsTotal(badPoints), isFalse);
    });
  });
}
