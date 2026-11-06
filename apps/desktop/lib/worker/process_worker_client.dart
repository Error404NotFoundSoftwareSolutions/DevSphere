// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Tests: TC-LNK-20..27
// Implemented here: the real client for the local worker process. It starts the worker program, talks
// JSON lines (one request per line, answers matched by id), validates every request against the IPC
// contract first, fails pending calls if the worker stops, and restarts it on the next call.
// This file may use dart:io because it is not in lib/ui or lib/features (SEC-03).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ipc_contract/ipc_contract.dart';
import 'worker_client.dart';

export 'worker_client.dart'
    show WorkerClient, WorkerException, UnavailableWorkerClient;

typedef RequestValidator = void Function(
    String channel, Map<String, dynamic> data);

class ProcessWorkerClient implements WorkerClient {
  ProcessWorkerClient({
    required this.executable,
    this.args = const [],
    this.timeout = const Duration(seconds: 120),
    this.validator = validateRequest,
  });

  final String executable;
  final List<String> args;
  final Duration timeout;
  final RequestValidator validator;

  Process? _process;
  Future<void>? _starting;
  int _nextId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};

  Future<void> _ensureStarted() {
    if (_process != null) return Future.value();
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    final Process p;
    try {
      p = await Process.start(executable, args, runInShell: false);
    } on ProcessException {
      throw WorkerException(
          code: 'unavailable',
          message: 'DevPilot could not start its helper program.',
          recovery: 'Reinstall DevPilot.');
    }
    final ready = Completer<void>();
    _process = p;
    p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        Object? j;
        try {
          j = jsonDecode(line);
        } on FormatException {
          return; // ignore anything that is not JSON
        }
        if (j is! Map) return;
        if (j['status'] == 'ready') {
          if (!ready.isCompleted) ready.complete();
          return;
        }
        final id = j['id'];
        final c = id is int ? _pending.remove(id) : null;
        if (c == null) return;
        final err = j['error'];
        if (err is Map) {
          c.completeError(WorkerException(
            code: '${err['code'] ?? 'failed'}',
            message:
                '${err['message'] ?? 'Something went wrong in DevPilot.'}',
            recovery: '${err['recovery'] ?? ''}',
          ));
        } else {
          final r = j['result'];
          c.complete(
              r is Map ? r.cast<String, dynamic>() : <String, dynamic>{});
        }
      },
      onDone: () => _onStopped(p, ready),
    );
    p.stderr.drain<void>();
    unawaited(p.exitCode.then((_) => _onStopped(p, ready)));
    await ready.future.timeout(const Duration(seconds: 15), onTimeout: () {
      p.kill();
      throw WorkerException(
          code: 'unavailable',
          message: 'DevPilot helper did not start.',
          recovery: 'Restart DevPilot.');
    });
  }

  void _onStopped(Process p, Completer<void> ready) {
    if (!identical(_process, p)) return;
    _process = null;
    final err = WorkerException(
        code: 'stopped',
        message: 'DevPilot helper stopped unexpectedly.',
        recovery: 'Try again.');
    if (!ready.isCompleted) ready.completeError(err);
    for (final c in _pending.values.toList()) {
      if (!c.isCompleted) c.completeError(err);
    }
    _pending.clear();
  }

  @override
  Future<Map<String, dynamic>> send(
      String channel, Map<String, dynamic> data) async {
    validator(channel, data);
    await _ensureStarted();
    final p = _process;
    if (p == null)
      throw WorkerException(
          code: 'stopped',
          message: 'DevPilot helper stopped unexpectedly.',
          recovery: 'Try again.');
    final id = ++_nextId;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    p.stdin.writeln(jsonEncode({'id': id, 'channel': channel, 'data': data}));
    return c.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      throw WorkerException(
          code: 'timeout',
          message: 'DevPilot took too long to answer.',
          recovery: 'Try again.');
    });
  }

  Future<void> dispose() async {
    final p = _process;
    _process = null;
    p?.kill();
  }
}
