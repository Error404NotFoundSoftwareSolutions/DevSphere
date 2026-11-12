// Shared helpers for the companion tests: a raw client that talks the extension protocol over a unix socket.

import 'dart:async';
import 'dart:io';
import 'package:local_worker/src/companion/protocol.dart';

class TestClient {
  TestClient._(this.socket);
  final Socket socket;
  final FrameDecoder _decoder = FrameDecoder();
  final List<Map<String, dynamic>> _queue = [];
  final List<Completer<void>> _waiters = [];
  final Completer<void> _closed = Completer<void>();
  Future<void> get closed => _closed.future;

  static Future<TestClient> connect(String path) async {
    final s = await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix), 0);
    final c = TestClient._(s);
    s.listen(
      (data) {
        try {
          for (final m in c._decoder.add(data)) {
            c._queue.add((m as Map).cast<String, dynamic>());
          }
        } on ProtocolError {
          s.destroy();
        }
        for (final w in c._waiters.toList()) {
          if (!w.isCompleted) w.complete();
        }
        c._waiters.clear();
      },
      onDone: () {
        if (!c._closed.isCompleted) c._closed.complete();
        for (final w in c._waiters.toList()) {
          if (!w.isCompleted) w.complete();
        }
      },
      onError: (_) {},
    );
    return c;
  }

  void send(Map<String, Object?> m) => socket.add(encodeFrame(m));
  void sendRaw(List<int> bytes) => socket.add(bytes);

  Future<Map<String, dynamic>> next(
      {Duration timeout = const Duration(seconds: 3)}) async {
    final end = DateTime.now().add(timeout);
    while (_queue.isEmpty) {
      if (_closed.isCompleted || DateTime.now().isAfter(end))
        throw TimeoutException('no message');
      final w = Completer<void>();
      _waiters.add(w);
      await w.future.timeout(end.difference(DateTime.now()), onTimeout: () {});
    }
    return _queue.removeAt(0);
  }

  Future<bool> waitClosed(
      {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      await closed.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> close() async {
    socket.destroy();
  }
}

Map<String, Object?> helloMsg(String sessionId, {int protocol = 1}) => {
      'type': 'hello',
      'protocol': protocol,
      'sessionId': sessionId,
      'extVersion': '0.1.0'
    };
