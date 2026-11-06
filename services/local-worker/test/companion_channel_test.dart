// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-SEC-002, NFR-SEC-003
// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Test IDs: TC-CMP-04-01..11. Threats T19, T20
// Implemented here: the local channel server: private socket, handshake, strict parsing, limits

import 'dart:io';
import 'dart:typed_data';
import 'package:local_worker/src/companion/channel_server.dart';
import 'package:local_worker/src/companion/protocol.dart';
import 'package:test/test.dart';
import 'companion_test_support.dart';

final sid = 'a1' * 16;

class FakeHandler implements RequestHandler {
  final List<ExtensionRequest> seen = [];
  @override
  Map<String, Object?> welcome() => welcomeEvent('python-hello-001');
  @override
  Future<List<Map<String, Object?>>> handle(ExtensionRequest r) async {
    seen.add(r);
    return [
      {'type': 'sessionClosed'}
    ];
  }
}

Future<(ChannelServer, FakeHandler, String, Directory)> start({Duration idle = const Duration(minutes: 5), int rate = 100}) async {
  final dir = Directory.systemTemp.createTempSync('bl-run-');
  final handler = FakeHandler();
  final server = ChannelServer(runtimeDir: '${dir.path}/run', sessionId: sid, handler: handler, idleTimeout: idle, maxRequestsPerSecond: rate);
  final path = await server.start();
  addTearDown(() async {
    await server.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return (server, handler, path, dir);
}

void main() {
  test('TC-CMP-04-01 runtime directory is 0700 and the socket is 0600 (T20)', () async {
    final (_, __, path, dir) = await start();
    expect(FileStat.statSync('${dir.path}/run').mode & 0x1FF, 0x1C0); // 0700
    expect(FileStat.statSync(path).mode & 0x1FF, 0x180); // 0600
  });

  test('TC-CMP-04-02 handshake then a request reaches the handler', () async {
    final (_, handler, path, __) = await start();
    final c = await TestClient.connect(path);
    c.send(helloMsg(sid));
    expect((await c.next())['type'], 'welcome');
    c.send({'type': 'getLabState'});
    expect((await c.next())['type'], 'sessionClosed'); // the fake handler's reply
    expect(handler.seen.single, isA<GetLabStateRequest>());
  });

  test('TC-CMP-04-03 a request before hello is refused and never reaches the handler', () async {
    final (_, handler, path, __) = await start();
    final c = await TestClient.connect(path);
    c.send({'type': 'runCheck', 'stepId': 'greet'});
    final e = await c.next();
    expect(e['code'], 'need-hello');
    expect(handler.seen, isEmpty);
  });

  test('TC-CMP-04-04 wrong session id gets an error and the connection is closed', () async {
    final (_, handler, path, __) = await start();
    final c = await TestClient.connect(path);
    c.send(helloMsg('b2' * 16));
    expect((await c.next())['code'], 'wrong-session');
    expect(await c.waitClosed(), isTrue);
    expect(handler.seen, isEmpty);
  });

  test('TC-CMP-04-05 a different protocol version gets protocol-mismatch and is closed', () async {
    final (_, __, path, ___) = await start();
    final c = await TestClient.connect(path);
    c.send(helloMsg(sid, protocol: 2));
    expect((await c.next())['code'], 'protocol-mismatch');
    expect(await c.waitClosed(), isTrue);
  });

  test('TC-CMP-04-06 forged messages (events, unknown types) are refused; three strikes close (T19)', () async {
    final (_, handler, path, __) = await start();
    final c = await TestClient.connect(path);
    c.send(helloMsg(sid));
    await c.next();
    for (var i = 0; i < 3; i++) {
      c.send({'type': 'checkResult', 'stepId': 'greet', 'passed': true, 'kind': 'Verified'});
      expect((await c.next())['code'], 'invalid-message');
    }
    expect(await c.waitClosed(), isTrue);
    expect(handler.seen, isEmpty);
  });

  test('TC-CMP-04-07 an oversize frame closes the connection without reaching the handler', () async {
    final (_, handler, path, __) = await start();
    final c = await TestClient.connect(path);
    final header = ByteData(4)..setUint32(0, maxFrameBytes + 1);
    c.sendRaw(header.buffer.asUint8List());
    expect(await c.waitClosed(), isTrue);
    expect(handler.seen, isEmpty);
  });

  test('TC-CMP-04-08 a second simultaneous connection is refused with busy', () async {
    final (_, __, path, ___) = await start();
    final first = await TestClient.connect(path);
    first.send(helloMsg(sid));
    await first.next();
    final second = await TestClient.connect(path);
    expect((await second.next())['code'], 'busy');
    expect(await second.waitClosed(), isTrue);
    await first.close();
  });

  test('TC-CMP-04-09 after the first client leaves, a new one may connect (window reload)', () async {
    final (_, __, path, ___) = await start();
    final first = await TestClient.connect(path);
    first.send(helloMsg(sid));
    await first.next();
    await first.close();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final again = await TestClient.connect(path);
    again.send(helloMsg(sid));
    expect((await again.next())['type'], 'welcome');
  });

  test('TC-CMP-04-10 idle timeout sends sessionClosed and closes', () async {
    final (_, __, path, ___) = await start(idle: const Duration(milliseconds: 300));
    final c = await TestClient.connect(path);
    c.send(helloMsg(sid));
    await c.next();
    expect((await c.next(timeout: const Duration(seconds: 3)))['type'], 'sessionClosed');
    expect(await c.waitClosed(), isTrue);
  });

  test('TC-CMP-04-11 a request flood is cut off, and close() removes the socket file', () async {
    final (server, _, path, __) = await start(rate: 5);
    final c = await TestClient.connect(path);
    c.send(helloMsg(sid));
    await c.next();
    for (var i = 0; i < 30; i++) {
      c.send({'type': 'getLabState'});
    }
    expect(await c.waitClosed(), isTrue);
    await server.close();
    expect(File(path).existsSync(), isFalse);
  });
}
