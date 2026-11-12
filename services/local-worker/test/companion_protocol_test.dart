// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-SEC-002, NFR-SEC-003
// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Test IDs: TC-CMP-01-01..08
// Implemented here: extension protocol v1: strict request parsing, framing, handshake gate

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:local_worker/src/companion/protocol.dart';
import 'package:test/test.dart';

List<MapEntry<String, Object?>> loadFixtures(String kind) {
  final dir = Directory('../../fixtures/protocol/$kind');
  return [
    for (final f in dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json')))
      MapEntry(f.uri.pathSegments.last, jsonDecode(f.readAsStringSync())),
  ]..sort((a, b) => a.key.compareTo(b.key));
}

void main() {
  test('TC-CMP-01-01 every valid fixture parses', () {
    final fixtures = loadFixtures('valid');
    expect(fixtures, isNotEmpty);
    for (final f in fixtures) {
      expect(parseRequest(f.value), isNotNull, reason: f.key);
    }
  });

  test('TC-CMP-01-02 every invalid fixture is rejected', () {
    final fixtures = loadFixtures('invalid');
    expect(fixtures.length, greaterThanOrEqualTo(10));
    for (final f in fixtures) {
      expect(parseRequest(f.value), isNull, reason: f.key);
    }
  });

  test('TC-CMP-01-03 parsed requests carry the right data', () {
    final hello = parseRequest({
      'type': 'hello',
      'protocol': 1,
      'sessionId': 'a' * 32,
      'extVersion': '1.2.3'
    });
    expect(hello, isA<HelloRequest>());
    expect((hello as HelloRequest).extVersion, '1.2.3');
    expect(
        (parseRequest({'type': 'runCheck', 'stepId': 'greet'})
                as RunCheckRequest)
            .stepId,
        'greet');
    expect(parseRequest({'type': 'finishLab'}), isA<FinishLabRequest>());
  });

  test(
      'TC-CMP-01-04 a frame round-trips and carries a 4-byte big-endian length',
      () {
    final bytes = encodeFrame(
        {'type': 'welcome', 'protocol': 1, 'labId': 'python-hello-001'});
    final len = ByteData.sublistView(bytes).getUint32(0);
    expect(len, bytes.length - 4);
    final out = FrameDecoder().add(bytes);
    expect(out, [
      {'type': 'welcome', 'protocol': 1, 'labId': 'python-hello-001'},
    ]);
  });

  test(
      'TC-CMP-01-05 the decoder handles split chunks and several frames at once',
      () {
    final a = encodeFrame({'type': 'finishLab'});
    final b = encodeFrame({'type': 'getLabState'});
    final all = Uint8List.fromList([...a, ...b]);
    final d = FrameDecoder();
    final got = <Object?>[];
    for (var i = 0; i < all.length; i += 3) {
      got.addAll(
          d.add(all.sublist(i, i + 3 > all.length ? all.length : i + 3)));
    }
    expect(got, [
      {'type': 'finishLab'},
      {'type': 'getLabState'},
    ]);
  });

  test(
      'TC-CMP-01-06 oversize, zero-length and non-JSON frames are protocol errors',
      () {
    final big = ByteData(4)..setUint32(0, maxFrameBytes + 1);
    expect(() => FrameDecoder().add(big.buffer.asUint8List()),
        throwsA(isA<ProtocolError>()));
    final zero = ByteData(4)..setUint32(0, 0);
    expect(() => FrameDecoder().add(zero.buffer.asUint8List()),
        throwsA(isA<ProtocolError>()));
    final junk = utf8.encode('not json');
    final framed = Uint8List.fromList([0, 0, 0, junk.length, ...junk]);
    expect(() => FrameDecoder().add(framed), throwsA(isA<ProtocolError>()));
    expect(() => encodeFrame({'x': 'a' * (maxFrameBytes + 1)}),
        throwsA(isA<ProtocolError>()));
  });

  test(
      'TC-CMP-01-07 handshake gate: hello first, matching session and protocol, no second hello',
      () {
    final sid = 'b' * 32;
    final gate = SessionGate(sid);
    expect(gate.check(const RunCheckRequest('greet')), GateDecision.needHello);
    expect(
        gate.check(HelloRequest(
            protocol: 1, sessionId: 'c' * 32, extVersion: '1.0.0')),
        GateDecision.wrongSession);
    expect(
        gate.check(
            HelloRequest(protocol: 2, sessionId: sid, extVersion: '1.0.0')),
        GateDecision.protocolMismatch);
    expect(
        gate.check(
            HelloRequest(protocol: 1, sessionId: sid, extVersion: '1.0.0')),
        GateDecision.allow);
    expect(gate.check(const RunCheckRequest('greet')), GateDecision.allow);
    expect(
        gate.check(
            HelloRequest(protocol: 1, sessionId: sid, extVersion: '1.0.0')),
        GateDecision.duplicateHello);
  });

  test(
      'TC-CMP-01-08 event builders only produce Practice results and bounded output',
      () {
    final e = checkResultEvent(
        stepId: 'greet', passed: true, summary: 'ok', output: 'x' * 10000);
    expect(e['kind'], 'Practice');
    expect((e['output'] as String).length, lessThanOrEqualTo(4000));
    expect(errorEvent('busy', 'Wait for the current check.')['type'], 'error');
    expect(() => errorEvent('made-up-code', 'x'), throwsArgumentError);
  });

  test('TC-CMP-01-09 event builders produce exactly the valid event fixtures',
      () {
    final fx = {
      for (final f in loadFixtures('events'))
        (f.value as Map)['type'] as String: f.value
    };
    expect(welcomeEvent('python-hello-001'), fx['welcome']);
    expect(
      labStateEvent(
          labId: 'python-hello-001',
          title: 'Hello, Python',
          currentStepId: 'setup',
          steps: [
            (
              id: 'setup',
              title: 'Open the starter file',
              state: 'todo',
              contentRef: 'guide/01-setup.md'
            ),
            (
              id: 'greet',
              title: 'Write the greet function',
              state: 'fail',
              contentRef: 'guide/02-greet.md'
            ),
          ]),
      fx['labState'],
    );
    expect(
      checkResultEvent(
          stepId: 'greet',
          passed: false,
          summary: 'Some checks did not pass yet.',
          output: 'assert None == "Hello, Asha!"'),
      fx['checkResult'],
    );
    expect(errorEvent('busy', 'Wait for the current check to finish.'),
        fx['error']);
  });
}
