// User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
// Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
// Implemented here: shared corpus test: fixtures/secrets/corpus.json is also used by the Python tests

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:redaction/redaction.dart';

void main() {
  group('TC-FR-AI-005-01 redaction corpus', () {
    late Map<String, dynamic> corpus;

    setUpAll(() {
      final file = File('../../fixtures/secrets/corpus.json');
      corpus = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('removes all secrets in corpus', () {
      final secrets = corpus['secrets'] as List;
      for (final item in secrets) {
        final name = item['name'] as String;
        final secret = item['secret'] as String;
        final text = item['text'] as String;
        final result = redact(text);
        expect(result.text, isNot(contains(secret)),
            reason: 'Failed to redact secret in $name');
      }
    });

    test('leaves clean text alone', () {
      final clean = corpus['clean'] as List;
      for (final item in clean) {
        final name = item['name'] as String;
        final text = item['text'] as String;
        final result = redact(text);
        expect(result.text, equals(text),
            reason: 'Clean text modified in $name');
      }
    });
  });
}

