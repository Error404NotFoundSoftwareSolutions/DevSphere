// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Rules: SEC-24, SEC-26. Threats T19, T20
// Implemented here: TC-CMP-10-01..07 finding the session file safely, TC-CMP-11-01..07 the channel client
import assert from 'node:assert/strict';
import fs from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { ChannelClient } from '../src/host/channel';
import { discoverSession } from '../src/host/session';
import { FrameDecoder, encodeFrame, type WorkerEvent } from '../src/core/protocol';

const SID = 'a1'.repeat(16);

function runtime(): { dir: string; lab: string } {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), 'bl-ext-'));
  const dir = path.join(base, 'run');
  const lab = path.join(base, 'lab');
  fs.mkdirSync(dir, { mode: 0o700 }); fs.chmodSync(dir, 0o700);
  fs.mkdirSync(lab);
  return { dir, lab };
}
function writeSession(dir: string, lab: string, over: Record<string, unknown> = {}, mode = 0o600): string {
  const file = path.join(dir, `session-${SID}.json`);
  fs.writeFileSync(file, JSON.stringify({ sessionId: SID, socketPath: path.join(dir, `session-${SID}.sock`), labId: 'python-hello-001', labRoot: lab, protocol: 1, ...over }), { mode });
  fs.chmodSync(file, mode);
  return file;
}

test('TC-CMP-10-01 finds the session for this lab folder', () => {
  const { dir, lab } = runtime();
  writeSession(dir, lab);
  const s = discoverSession(lab, dir);
  assert.equal(s?.sessionId, SID);
  assert.equal(s?.labId, 'python-hello-001');
});

test('TC-CMP-10-02 ignores a session for a different lab folder', () => {
  const { dir, lab } = runtime();
  writeSession(dir, path.join(lab, 'elsewhere'));
  assert.equal(discoverSession(lab, dir), undefined);
});

test('TC-CMP-10-03 refuses a session file that others can read or write (T20)', () => {
  const { dir, lab } = runtime();
  writeSession(dir, lab, {}, 0o644);
  assert.equal(discoverSession(lab, dir), undefined);
});

test('TC-CMP-10-04 refuses a runtime directory that others can enter (T20)', () => {
  const { dir, lab } = runtime();
  writeSession(dir, lab);
  fs.chmodSync(dir, 0o755);
  assert.equal(discoverSession(lab, dir), undefined);
});

test('TC-CMP-10-05 refuses a symlinked session file', () => {
  const { dir, lab } = runtime();
  const real = writeSession(dir, lab);
  const moved = path.join(path.dirname(dir), 'real.json');
  fs.renameSync(real, moved);
  fs.symlinkSync(moved, real);
  assert.equal(discoverSession(lab, dir), undefined);
});

test('TC-CMP-10-06 refuses malformed or hostile session content', () => {
  for (const over of [{ sessionId: 'short' }, { labId: '../x' }, { protocol: 2 }, { socketPath: '/etc/passwd' }, { socketPath: 'relative.sock' }]) {
    const { dir, lab } = runtime();
    writeSession(dir, lab, over);
    assert.equal(discoverSession(lab, dir), undefined, JSON.stringify(over));
  }
  const { dir, lab } = runtime();
  fs.writeFileSync(path.join(dir, `session-${SID}.json`), 'not json', { mode: 0o600 });
  assert.equal(discoverSession(lab, dir), undefined);
});

test('TC-CMP-10-07 a missing runtime directory is simply "no session"', () => {
  assert.equal(discoverSession('/tmp', '/nonexistent/devpilot/run'), undefined);
});

// ---------------------------------------------------------------- client against a fake worker

interface Fake { path: string; server: net.Server; received: unknown[]; sockets: net.Socket[]; }
async function fakeWorker(onFrame: (msg: Record<string, unknown>, s: net.Socket) => void): Promise<Fake> {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bl-fw-'));
  const p = path.join(dir, 's.sock');
  const received: unknown[] = []; const sockets: net.Socket[] = [];
  const server = net.createServer((s) => {
    sockets.push(s);
    const d = new FrameDecoder();
    s.on('data', (c) => { try { for (const m of d.push(c)) { received.push(m); onFrame(m as Record<string, unknown>, s); } } catch { s.destroy(); } });
    s.on('error', () => undefined);
  });
  await new Promise<void>((r) => server.listen(p, r));
  return { path: p, server, received, sockets };
}
const send = (s: net.Socket, m: Record<string, unknown>): void => { s.write(encodeFrame(m)); };
const session = (p: string) => ({ sessionId: SID, socketPath: p, labId: 'python-hello-001', labRoot: '/x', protocol: 1 as const });
const welcome = { type: 'welcome', protocol: 1, labId: 'python-hello-001' };

test('TC-CMP-11-01 connects, says hello with the session id, and resolves on welcome', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, welcome); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  await c.connect();
  assert.deepEqual(f.received[0], { type: 'hello', protocol: 1, sessionId: SID, extVersion: '0.1.0' });
  c.close(); f.server.close();
});

test('TC-CMP-11-02 delivers valid events and drops invalid ones', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, welcome); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  const events: WorkerEvent[] = [];
  c.onEvent((e) => events.push(e));
  await c.connect();
  send(f.sockets[0]!, { type: 'badge', name: 'first-function' });
  send(f.sockets[0]!, { type: 'checkResult', stepId: 'greet', passed: true, kind: 'Verified', summary: '', output: '' });
  send(f.sockets[0]!, { type: 'sessionClosed' });
  await new Promise((r) => setTimeout(r, 150));
  assert.deepEqual(events.map((e) => e.type), ['sessionClosed']);
  c.close(); f.server.close();
});

test('TC-CMP-11-03 an error reply to hello rejects with the plain message', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, { type: 'error', code: 'protocol-mismatch', message: 'Update DevPilot.' }); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  await assert.rejects(c.connect(), /Update DevPilot/);
  f.server.close();
});

test('TC-CMP-11-04 a welcome for a different lab is refused', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, { ...welcome, labId: 'other-lab-001' }); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  await assert.rejects(c.connect(), /different lab/i);
  f.server.close();
});

test('TC-CMP-11-05 no welcome within the timeout rejects', async () => {
  const f = await fakeWorker(() => undefined);
  const c = new ChannelClient(session(f.path), '0.1.0', { handshakeTimeoutMs: 200 });
  await assert.rejects(c.connect(), /did not answer/i);
  f.server.close();
});

test('TC-CMP-11-06 an oversize frame from the worker closes the connection', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, welcome); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  let closed = false;
  c.onClose(() => { closed = true; });
  await c.connect();
  const head = Buffer.alloc(4); head.writeUInt32BE(10_000_000);
  f.sockets[0]!.write(head);
  await new Promise((r) => setTimeout(r, 150));
  assert.equal(closed, true);
  f.server.close();
});

test('TC-CMP-11-07 only valid requests can be sent, and nothing is sent when not connected', async () => {
  const f = await fakeWorker((m, s) => { if (m.type === 'hello') send(s, welcome); });
  const c = new ChannelClient(session(f.path), '0.1.0');
  assert.throws(() => c.send({ type: 'getLabState' }), /not connected/i);
  await c.connect();
  c.send({ type: 'runCheck', stepId: 'greet' });
  await new Promise((r) => setTimeout(r, 100));
  assert.deepEqual(f.received[1], { type: 'runCheck', stepId: 'greet' });
  assert.throws(() => c.send({ type: 'runCheck', stepId: '../../x' }));
  c.close(); f.server.close();
});
