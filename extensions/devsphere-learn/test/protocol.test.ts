// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Rules: SEC-21, SEC-26, ARC-03. Spec: docs/EXTENSION_PROTOCOL.md
// Implemented here: TC-CMP-09-01..06 extension-side protocol: strict event parsing, framing, shared fixtures
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { FrameDecoder, MAX_FRAME_BYTES, ProtocolError, encodeFrame, parseEvent, requests } from '../src/core/protocol';

const FX = path.resolve(__dirname, '../../../../fixtures/protocol');
function load(kind: string): [string, unknown][] {
  return fs.readdirSync(path.join(FX, kind)).filter((f) => f.endsWith('.json')).sort()
    .map((f) => [f, JSON.parse(fs.readFileSync(path.join(FX, kind, f), 'utf8')) as unknown]);
}

test('TC-CMP-09-01 every valid event fixture parses', () => {
  const fixtures = load('events');
  assert.ok(fixtures.length >= 5);
  for (const [name, value] of fixtures) assert.ok(parseEvent(value), name);
});

test('TC-CMP-09-02 every invalid event fixture is rejected (no Verified, no unknown types, no traversal)', () => {
  const fixtures = load('events-invalid');
  assert.ok(fixtures.length >= 7);
  for (const [name, value] of fixtures) assert.equal(parseEvent(value), undefined, name);
});

test('TC-CMP-09-03 request builders produce exactly the valid request fixtures', () => {
  const byType = new Map(load('valid').map(([, v]) => [(v as { type: string }).type, v]));
  const hello = byType.get('hello') as { sessionId: string; extVersion: string };
  assert.deepEqual(requests.hello(hello.sessionId, hello.extVersion), byType.get('hello'));
  assert.deepEqual(requests.getLabState(), byType.get('getLabState'));
  assert.deepEqual(requests.runCheck('greet'), byType.get('runCheck'));
  assert.deepEqual(requests.goStep('setup'), byType.get('goStep'));
  assert.deepEqual(requests.finishLab(), byType.get('finishLab'));
});

test('TC-CMP-09-04 request builders refuse bad ids so the extension never sends junk', () => {
  assert.throws(() => requests.runCheck('../../x'));
  assert.throws(() => requests.goStep('A B'));
  assert.throws(() => requests.hello('short', '1.0.0'));
});

test('TC-CMP-09-05 frames round-trip, split across chunks and glued together', () => {
  const a = encodeFrame({ type: 'getLabState' });
  const b = encodeFrame({ type: 'finishLab' });
  assert.equal(a.readUInt32BE(0), a.length - 4);
  const all = Buffer.concat([a, b]);
  const d = new FrameDecoder();
  const got: unknown[] = [];
  for (let i = 0; i < all.length; i += 3) got.push(...d.push(all.subarray(i, i + 3)));
  assert.deepEqual(got, [{ type: 'getLabState' }, { type: 'finishLab' }]);
});

test('TC-CMP-09-06 oversize, zero-length and non-JSON frames are protocol errors', () => {
  const big = Buffer.alloc(4); big.writeUInt32BE(MAX_FRAME_BYTES + 1);
  assert.throws(() => new FrameDecoder().push(big), ProtocolError);
  assert.throws(() => new FrameDecoder().push(Buffer.alloc(4)), ProtocolError);
  const junk = Buffer.from('not json'); const head = Buffer.alloc(4); head.writeUInt32BE(junk.length);
  assert.throws(() => new FrameDecoder().push(Buffer.concat([head, junk])), ProtocolError);
  assert.throws(() => encodeFrame({ x: 'a'.repeat(MAX_FRAME_BYTES + 1) }), ProtocolError);
});
