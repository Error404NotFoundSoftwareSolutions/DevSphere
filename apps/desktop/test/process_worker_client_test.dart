// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, NFR-SEC-002..003
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Test IDs: TC-LNK-20..27
// Implemented here: the app's real client for the worker process (JSON lines, one id per request)

import 'package:desktop/worker/process_worker_client.dart';
import 'package:flutter_test/flutter_test.dart';

ProcessWorkerClient make({Duration timeout = const Duration(seconds: 20)}) {
  final c = ProcessWorkerClient(
    executable: 'dart',
    args: const ['run', 'test/support/fake_worker.dart'],
    timeout: timeout,
    validator: (channel, data) {},
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('TC-LNK-20 sends a request and returns the result for its id', () async {
    final c = make();
    expect(await c.send('echo', {'a': 1}), {'a': 1});
  });

  test('TC-LNK-21 concurrent requests get their own answers', () async {
    final c = make();
    final results = await Future.wait([for (var i = 0; i < 5; i++) c.send('echo', {'n': i})]);
    expect([for (final r in results) r['n']], [0, 1, 2, 3, 4]);
  });

  test('TC-LNK-22 an error answer becomes a WorkerException with code, message and recovery', () async {
    final c = make();
    await expectLater(
      c.send('fail', {}),
      throwsA(isA<WorkerException>().having((e) => e.message, 'message', 'It did not work.').having((e) => e.recovery, 'recovery', 'Try again.')),
    );
  });

  test('TC-LNK-23 a request that takes too long times out with a plain message', () async {
    final c = make(timeout: const Duration(milliseconds: 500));
    await expectLater(c.send('slow', {}), throwsA(isA<WorkerException>().having((e) => e.code, 'code', 'timeout')));
  });

  test('TC-LNK-24 if the worker crashes, pending calls fail and the next call restarts it', () async {
    final c = make();
    expect(await c.send('echo', {'x': 1}), {'x': 1});
    await expectLater(c.send('crash', {}), throwsA(isA<WorkerException>().having((e) => e.code, 'code', 'stopped')));
    expect(await c.send('echo', {'x': 2}), {'x': 2});
  });

  test('TC-LNK-25 non-JSON lines from the worker are ignored', () async {
    final c = make();
    expect(await c.send('garbage', {}), {'after': 'garbage'});
  });

  test('TC-LNK-26 a missing worker program gives a plain message, not a crash', () async {
    final c = ProcessWorkerClient(executable: '/definitely/not/here/worker', validator: (channel, data) {});
    await expectLater(c.send('echo', {}), throwsA(isA<WorkerException>().having((e) => e.code, 'code', 'unavailable')));
  });

  test('TC-LNK-27 requests are validated against the contract before they are sent', () async {
    final c = ProcessWorkerClient(executable: 'dart', args: const ['run', 'test/support/fake_worker.dart']);
    addTearDown(c.dispose);
    await expectLater(c.send('system:rmrf', {}), throwsA(anything));
    await expectLater(c.send('companion:launch', {'labId': '../x'}), throwsA(anything));
  });
}
