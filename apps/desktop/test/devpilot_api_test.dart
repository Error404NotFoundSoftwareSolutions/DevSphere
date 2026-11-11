// Capability: CAP-AI-CLIENT. Rules: NFR-SEC-004. Tests: TC-API-01..07
// Implemented here: the app's API client sends the person's sign-in token, speaks the API's format, and turns
// every failure into a plain sentence with a next step.
import 'dart:convert';
import 'package:desktop/services/devpilot_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

HttpDevPilotApi api(MockClient c, {String? token = 'tok-123'}) =>
    HttpDevPilotApi(baseUrl: 'http://api.test', token: () async => token, client: c);

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('TC-API-01 roadmap posts the request with the bearer token and returns the answer', () async {
    late http.Request seen;
    final a = api(MockClient((r) async {
      seen = r;
      return json({'title': 'T', 'steps': []});
    }));
    final out = await a.roadmap(kind: 'topic', text: 'python', level: 'beginner');
    expect(out['title'], 'T');
    expect(seen.url.toString(), 'http://api.test/v1/ai/roadmap');
    expect(seen.headers['Authorization'], 'Bearer tok-123');
    expect(jsonDecode(seen.body), {'kind': 'topic', 'text': 'python', 'level': 'beginner'});
  });

  test('TC-API-02 without a signed-in person nothing is sent', () async {
    var calls = 0;
    final a = api(MockClient((r) async {
      calls++;
      return json({});
    }), token: null);
    await expectLater(a.roadmap(kind: 'topic', text: 'x'), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 401)));
    expect(calls, 0);
  });

  test('TC-API-03 the API\'s own error message and recovery are passed on', () async {
    final a = api(MockClient((r) async => json({
          'detail': {'code': 'limit', 'message': 'You have reached today\'s limit for this AI feature.', 'recovery': 'Try again tomorrow.'}
        }, 429)));
    await expectLater(
      a.roadmap(kind: 'topic', text: 'x'),
      throwsA(isA<ApiProblem>().having((e) => e.toString(), 'text', contains('today')).having((e) => e.recovery, 'recovery', 'Try again tomorrow.')),
    );
  });

  test('TC-API-04 an expired sign-in and a server error give plain advice, never raw text', () async {
    await expectLater(api(MockClient((r) async => http.Response('<html>boom</html>', 401))).roadmap(kind: 'topic', text: 'x'),
        throwsA(isA<ApiProblem>().having((e) => e.toString(), 't', allOf(contains('expired'), isNot(contains('html'))))));
    await expectLater(api(MockClient((r) async => http.Response('trace...', 500))).roadmap(kind: 'topic', text: 'x'),
        throwsA(isA<ApiProblem>().having((e) => e.toString(), 't', isNot(contains('trace')))));
  });

  test('TC-API-05 when the service cannot be reached the message says how to start it', () async {
    final a = api(MockClient((r) async => throw http.ClientException('connection refused')));
    await expectLater(a.roadmap(kind: 'topic', text: 'x'), throwsA(isA<ApiProblem>().having((e) => e.toString(), 't', contains('start.sh'))));
  });

  test('TC-API-06 an attempt is opened once per lab and the tutor request carries language and the maximum level', () async {
    final bodies = <String, Map<String, dynamic>>{};
    var attempts = 0;
    final a = api(MockClient((r) async {
      bodies[r.url.path] = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.url.path == '/v1/attempts') {
        attempts++;
        return json({'id': 'att-1'}, 201);
      }
      return json({'answer': 'Think about the index.', 'level': 3});
    }));
    expect(await a.attemptFor('python-hello-001'), 'att-1');
    expect(await a.attemptFor('python-hello-001'), 'att-1');
    expect(attempts, 1, reason: 'cached');
    final t = await a.ask(attemptId: 'att-1', question: 'why?', language: 'kn');
    expect(t.answer, 'Think about the index.');
    expect(t.level, 3);
    expect(bodies['/v1/tutor/messages'], {'attempt_id': 'att-1', 'question': 'why?', 'level': 6, 'language': 'kn'});
  });

  test('TC-API-07 the offline client fails with the same plain message', () async {
    await expectLater(const OfflineDevPilotApi().roadmap(kind: 'topic', text: 'x'), throwsA(isA<ApiProblem>()));
  });
}
