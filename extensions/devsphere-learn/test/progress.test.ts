// Capability: CAP-COURSE-PLAYER, CAP-BADGES. Rules: TRU-01, TRU-02, SEC-06 (stored data is untrusted).
// Implemented here: TC-LRN-40-01..06 progress store and badge rules, TC-LRN-41-01..02 catalogue validation
import assert from 'node:assert/strict';
import test from 'node:test';
import { badgeState, emptyProgress, labSummary, parseProgress, recordPractice } from '../src/core/progress';
import { parseCatalogue } from '../src/core/catalogue';
import { NotConfiguredGrader } from '../src/core/grader';

const T = '2026-11-04T10:00:00.000Z';

test('TC-LRN-40-01 empty progress has no labs', () => {
  assert.deepEqual(emptyProgress(), { version: 1, labs: {} });
});

test('TC-LRN-40-02 recordPractice is immutable and stores pass/fail with time', () => {
  const p0 = emptyProgress();
  const p1 = recordPractice(p0, 'lab-one', 'step-a', 'pass', T);
  assert.deepEqual(p0.labs, {});
  assert.equal(p1.labs['lab-one']?.steps['step-a']?.practice, 'pass');
});

test('TC-LRN-40-03 summary counts passes against total steps', () => {
  let p = recordPractice(emptyProgress(), 'lab-one', 'a', 'pass', T);
  p = recordPractice(p, 'lab-one', 'b', 'fail', T);
  assert.deepEqual(labSummary(p, 'lab-one', ['a', 'b', 'c']), { passed: 1, total: 3, complete: false });
  p = recordPractice(p, 'lab-one', 'b', 'pass', T);
  p = recordPractice(p, 'lab-one', 'c', 'pass', T);
  assert.equal(labSummary(p, 'lab-one', ['a', 'b', 'c']).complete, true);
});

test('TC-LRN-40-04 a badge is never earned from Practice alone (TRU-02)', () => {
  let p = emptyProgress();
  for (const s of ['a', 'b']) p = recordPractice(p, 'lab-one', s, 'pass', T);
  assert.equal(badgeState(p, 'lab-one', ['a', 'b']), 'pending-verification');
  assert.equal(badgeState(emptyProgress(), 'lab-one', ['a', 'b']), 'locked');
});

test('TC-LRN-40-05 parseProgress resets on corrupt or hostile data', () => {
  for (const bad of [null, 'x', 1, [], { version: 2 }, { version: 1, labs: 'x' },
    { version: 1, labs: { '../x': { steps: {} } } },
    { version: 1, labs: { ok: { steps: { a: { practice: 'maybe', at: T } } } } },
    JSON.parse('{"version":1,"labs":{"__proto__":{"steps":{}}}}')]) {
    assert.deepEqual(parseProgress(bad), emptyProgress(), JSON.stringify(bad));
  }
});

test('TC-LRN-40-06 parseProgress keeps valid data', () => {
  const p = recordPractice(emptyProgress(), 'lab-one', 'a', 'pass', T);
  assert.deepEqual(parseProgress(JSON.parse(JSON.stringify(p))), p);
});

test('TC-LRN-41-01 catalogue validation accepts the sample shape and rejects junk', () => {
  const ok = {
    version: 1, learner: 'Learner', weeklyGoal: { target: 3 },
    courses: [{ id: 'python-hello-001', title: 'Hello, Python', topic: 'Getting started', minutes: 45, level: 'beginner', available: true }],
    roadmap: { title: 'First project', steps: [{ courseId: 'python-hello-001', title: 'Hello, Python' }] },
    badges: [{ id: 'first-function', title: 'First function', courseId: 'python-hello-001' }],
  };
  assert.equal(parseCatalogue(ok).courses.length, 1);
  assert.throws(() => parseCatalogue({ ...ok, courses: [{ ...ok.courses[0], id: '../x' }] }), /catalogue/i);
  assert.throws(() => parseCatalogue('x'), /catalogue/i);
  assert.throws(() => parseCatalogue({ ...ok, weeklyGoal: { target: 9999 } }), /catalogue/i);
});

test('TC-LRN-41-02 grader port is not configured by default and says so plainly', async () => {
  const r = await new NotConfiguredGrader().submit('lab-one');
  assert.equal(r.status, 'unavailable');
  assert.match(r.message, /not connected/i);
});
