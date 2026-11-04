// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..008, FR-GRADE-002, NFR-SEC-005
// Capability: CAP-APP-EXT-CHANNEL (ADR-019). Test IDs: TC-CMP-05-01..08
// Implemented here: the worker-side lab controller: state, navigation, checks, finish. The worker decides.

import 'dart:async';
import 'package:local_worker/src/companion/lab_session.dart';
import 'package:local_worker/src/companion/protocol.dart';
import 'package:test/test.dart';

const lab = LabInfo(id: 'python-hello-001', title: 'Hello, Python', steps: [
  LabStepInfo(id: 'setup', title: 'Open the starter file', contentRef: 'guide/01-setup.md', hasCheck: false),
  LabStepInfo(id: 'greet', title: 'Write greet', contentRef: 'guide/02-greet.md', hasCheck: true),
]);

LabSessionController make({CheckRunner? runner, List<String>? practice, void Function(bool)? onFinish}) => LabSessionController(
      lab: lab,
      runCheck: runner ?? (s) async => const CheckOutcome(passed: true, summary: 'All checks passed.', output: '1 passed'),
      onPractice: (stepId, passed) => practice?.add('$stepId:$passed'),
      onFinishRequested: onFinish ?? (_) {},
    );

List<dynamic> steps(Map<String, Object?> e) => e['steps']! as List<dynamic>;

void main() {
  test('TC-CMP-05-01 welcome and lab state list every step as todo with the first one current', () async {
    final c = make();
    expect(c.welcome()['labId'], 'python-hello-001');
    final e = (await c.handle(const GetLabStateRequest())).single;
    expect(e['type'], 'labState');
    expect(e['currentStepId'], 'setup');
    expect(steps(e).map((s) => (s as Map)['state']), ['todo', 'todo']);
    expect((steps(e).first as Map)['contentRef'], 'guide/01-setup.md');
  });

  test('TC-CMP-05-02 goStep moves the guide and rejects unknown steps', () async {
    final c = make();
    final ok = (await c.handle(const GoStepRequest('greet'))).single;
    expect(ok['currentStepId'], 'greet');
    final bad = (await c.handle(const GoStepRequest('nope'))).single;
    expect(bad['code'], 'unknown-step');
  });

  test('TC-CMP-05-03 runCheck runs the worker check, records Practice and returns result plus state', () async {
    final log = <String>[];
    final c = make(practice: log);
    final out = await c.handle(const RunCheckRequest('greet'));
    expect(out.first['type'], 'checkResult');
    expect(out.first['kind'], 'Practice');
    expect(out.first['passed'], true);
    expect(out.last['type'], 'labState');
    expect((steps(out.last)[1] as Map)['state'], 'pass');
    expect(log, ['greet:true']);
  });

  test('TC-CMP-05-04 a failing check marks the step fail; a step without a check is marked done', () async {
    final c = make(runner: (s) async => const CheckOutcome(passed: false, summary: 'Not yet.', output: 'assert'));
    var out = await c.handle(const RunCheckRequest('greet'));
    expect(out.first['passed'], false);
    expect((steps(out.last)[1] as Map)['state'], 'fail');
    out = await c.handle(const RunCheckRequest('setup'));
    expect(out.first['passed'], true);
    expect(out.first['summary'], contains('done'));
  });

  test('TC-CMP-05-05 only one check runs at a time (busy)', () async {
    final gate = Completer<void>();
    final c = make(runner: (s) async {
      await gate.future;
      return const CheckOutcome(passed: true, summary: 'ok', output: '');
    });
    final first = c.handle(const RunCheckRequest('greet'));
    final second = await c.handle(const RunCheckRequest('greet'));
    expect(second.single['code'], 'busy');
    gate.complete();
    expect((await first).first['type'], 'checkResult');
  });

  test('TC-CMP-05-06 unknown step ids never reach the check runner', () async {
    var called = false;
    final c = make(runner: (s) async {
      called = true;
      return const CheckOutcome(passed: true, summary: '', output: '');
    });
    expect((await c.handle(const RunCheckRequest('../../x'))).single['code'], 'unknown-step');
    expect(called, isFalse);
  });

  test('TC-CMP-05-07 finishLab needs every step passed; then it asks the app to submit', () async {
    bool? finished;
    final c = make(onFinish: (all) => finished = all);
    expect((await c.handle(const FinishLabRequest())).single['code'], 'steps-incomplete');
    expect(finished, isNull);
    await c.handle(const RunCheckRequest('setup'));
    await c.handle(const RunCheckRequest('greet'));
    final out = await c.handle(const FinishLabRequest());
    expect(out.single['type'], 'labState');
    expect(finished, isTrue);
  });

  test('TC-CMP-05-08 check output is redacted and bounded before it leaves the worker (T6)', () async {
    final c = make(runner: (s) async => CheckOutcome(passed: false, summary: 's', output: 'token = "${'ghp_'}${'a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8'}" ${'x' * 9000}'));
    final out = (await c.handle(const RunCheckRequest('greet'))).first;
    final text = out['output'] as String;
    expect(text, isNot(contains('ghp_a1B2c3D4')));
    expect(text.length, lessThanOrEqualTo(maxCheckOutputChars));
  });
}
