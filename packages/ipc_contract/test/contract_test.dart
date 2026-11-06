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

  group('TC-CMP-12 companion channels (ADR-022)', () {
    test('TC-CMP-12-01 status takes no fields', () {
      expect(() => validateRequest('companion:status', {}), returnsNormally);
      expect(() => validateRequest('companion:status', {'path': '/usr/bin/code'}), throwsA(isA<IpcValidationException>()));
    });

    test('TC-CMP-12-02 install needs an explicit boolean approval and nothing else', () {
      expect(() => validateRequest('companion:install', {'approved': true}), returnsNormally);
      expect(() => validateRequest('companion:install', {}), throwsA(isA<IpcValidationException>()));
      expect(() => validateRequest('companion:install', {'approved': 'yes'}), throwsA(isA<IpcValidationException>()));
      expect(() => validateRequest('companion:install', {'approved': true, 'vsix': '/tmp/evil.vsix'}), throwsA(isA<IpcValidationException>()));
    });

    test('TC-CMP-12-03 launch and sessionState take only a lab id, never a path or command', () {
      for (final c in ['companion:launch', 'companion:sessionState']) {
        expect(() => validateRequest(c, {'labId': 'python-hello-001'}), returnsNormally, reason: c);
        expect(() => validateRequest(c, {'labId': '../x'}), throwsA(isA<IpcValidationException>()), reason: c);
        expect(() => validateRequest(c, {'labId': 'a b'}), throwsA(isA<IpcValidationException>()), reason: c);
        expect(() => validateRequest(c, {'labId': 'python-hello-001', 'cmd': 'code'}), throwsA(isA<IpcValidationException>()), reason: c);
        expect(() => validateRequest(c, {}), throwsA(isA<IpcValidationException>()), reason: c);
      }
    });
  });
}
