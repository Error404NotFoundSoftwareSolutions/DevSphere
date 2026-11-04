// Capability: CAP-COURSE-PLAYER. Rules: SEC-21 (postMessage validated), SEC-26.
// Implemented here: TC-SEC-19-01..03 webview message validation
import assert from 'node:assert/strict';
import test from 'node:test';
import { parseMessage } from '../src/core/messages';

test('TC-SEC-19-01 accepts the known messages', () => {
  assert.deepEqual(parseMessage({ type: 'openCourse', courseId: 'python-hello-001' }), { type: 'openCourse', courseId: 'python-hello-001' });
  assert.deepEqual(parseMessage({ type: 'checkStep', stepId: 'greet' }), { type: 'checkStep', stepId: 'greet' });
  assert.deepEqual(parseMessage({ type: 'goStep', stepId: 'setup' }), { type: 'goStep', stepId: 'setup' });
  assert.deepEqual(parseMessage({ type: 'openHome' }), { type: 'openHome' });
  assert.deepEqual(parseMessage({ type: 'finish' }), { type: 'finish' });
});

test('TC-SEC-19-02 drops unknown types, extra keys, bad ids and non-objects', () => {
  const bad: unknown[] = [
    null, 'x', 42, [], {}, { type: 'exec', cmd: 'rm -rf /' },
    { type: 'openCourse' }, { type: 'openCourse', courseId: '../x' },
    { type: 'openCourse', courseId: 'a b' }, { type: 'checkStep', stepId: 'x'.repeat(200) },
    { type: 'openHome', extra: 1 }, { type: 'checkStep', stepId: { $ne: 1 } },
  ];
  for (const b of bad) assert.equal(parseMessage(b), undefined, JSON.stringify(b));
});

test('TC-SEC-19-03 prototype pollution style keys do not slip through', () => {
  const evil = JSON.parse('{"type":"openHome","__proto__":{"x":1}}');
  assert.equal(parseMessage(evil), undefined);
});
