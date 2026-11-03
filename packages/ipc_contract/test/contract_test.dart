// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: TC-NFR-SEC-002-01: IPC contract validation tests

import 'package:test/test.dart';
import 'package:ipc_contract/ipc_contract.dart';

void main() {
  group('TC-NFR-SEC-002-01 ipc contract', () {
    test('accepts a valid request', () {
      expect(
        () => validateRequest('task:run', {'attemptId': 'att-123', 'taskId': 'task-1'}),
        returnsNormally,
      );
    });

    test('rejects an unknown channel', () {
      expect(
        () => validateRequest('system:rmrf', {}),
        throwsA(isA<IpcValidationException>()),
      );
    });

    test('rejects unknown fields (no raw command smuggling)', () {
      expect(
        () => validateRequest('task:run', {
          'attemptId': 'att-123',
          'taskId': 'task-1',
          'rawCommand': 'rm -rf /',
        }),
        throwsA(isA<IpcValidationException>()),
      );
    });

    test('has a schema for every channel', () {
      for (final channel in channels) {
        expect(channelSchemas.containsKey(channel), isTrue,
            reason: 'Missing schema for channel: $channel');
      }
    });
  });
}

