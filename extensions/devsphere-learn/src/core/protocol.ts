// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Spec: docs/EXTENSION_PROTOCOL.md. Rules: SEC-21, SEC-26, ARC-03
// Tests: TC-CMP-09-xx (shared fixtures in fixtures/protocol)
// Implemented here: the extension side of the protocol. Events from the worker are parsed strictly (the
// worker is trusted, but bugs and a spoofed socket must not break the panel); requests can only be built
// through validated builders; frames are bounded.
import { isId, isPlainText } from './ids';

export const PROTOCOL_VERSION = 1;
export const MAX_FRAME_BYTES = 64 * 1024;

export class ProtocolError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ProtocolError';
  }
}

export type StepState = 'todo' | 'pass' | 'fail';
export interface LabStateStep { id: string; title: string; state: StepState; contentRef: string }
export type WorkerEvent =
  | { type: 'welcome'; protocol: number; labId: string }
  | { type: 'labState'; labId: string; title: string; currentStepId: string; steps: LabStateStep[] }
  | { type: 'checkResult'; stepId: string; passed: boolean; kind: 'Practice'; summary: string; output: string }
  | { type: 'error'; code: string; message: string }
  | { type: 'sessionClosed' };

export type ExtRequest =
  | { type: 'hello'; protocol: number; sessionId: string; extVersion: string }
  | { type: 'getLabState' }
  | { type: 'runCheck'; stepId: string }
  | { type: 'goStep'; stepId: string }
  | { type: 'finishLab' };

const ERROR_CODES = new Set(['protocol-mismatch', 'wrong-session', 'need-hello', 'duplicate-hello', 'unknown-step', 'invalid-message', 'busy', 'steps-incomplete']);
const STATES = new Set(['todo', 'pass', 'fail']);
const SESSION_RE = /^[a-f0-9]{32}$/;
const SEMVER_RE = /^\d{1,4}\.\d{1,4}\.\d{1,4}$/;
const REF_RE = /^[A-Za-z0-9][A-Za-z0-9_./-]{0,120}\.md$/;

type Obj = Record<string, unknown>;
const isObj = (v: unknown): v is Obj => typeof v === 'object' && v !== null && !Array.isArray(v);
const exactKeys = (o: Obj, keys: string[]): boolean => {
  const own = Object.keys(o);
  return own.length === keys.length && keys.every((k) => own.includes(k));
};
const safeRef = (v: unknown): v is string => typeof v === 'string' && REF_RE.test(v) && !v.split('/').some((s) => s === '..' || s === '.' || s === '');

export function parseEvent(raw: unknown): WorkerEvent | undefined {
  if (!isObj(raw)) return undefined;
  switch (raw.type) {
    case 'welcome':
      return exactKeys(raw, ['type', 'protocol', 'labId']) && typeof raw.protocol === 'number' && isId(raw.labId)
        ? { type: 'welcome', protocol: raw.protocol, labId: raw.labId } : undefined;
    case 'labState': {
      if (!exactKeys(raw, ['type', 'labId', 'title', 'currentStepId', 'steps'])) return undefined;
      if (!isId(raw.labId) || !isPlainText(raw.title, 120) || !(raw.currentStepId === '' || isId(raw.currentStepId))) return undefined;
      if (!Array.isArray(raw.steps) || raw.steps.length > 50) return undefined;
      const steps: LabStateStep[] = [];
      for (const s of raw.steps as unknown[]) {
        if (!isObj(s) || !exactKeys(s, ['id', 'title', 'state', 'contentRef'])) return undefined;
        if (!isId(s.id) || !isPlainText(s.title, 120) || typeof s.state !== 'string' || !STATES.has(s.state) || !safeRef(s.contentRef)) return undefined;
        steps.push({ id: s.id, title: s.title, state: s.state as StepState, contentRef: s.contentRef });
      }
      return { type: 'labState', labId: raw.labId, title: raw.title, currentStepId: raw.currentStepId as string, steps };
    }
    case 'checkResult':
      return exactKeys(raw, ['type', 'stepId', 'passed', 'kind', 'summary', 'output'])
        && isId(raw.stepId) && typeof raw.passed === 'boolean' && raw.kind === 'Practice'
        && typeof raw.summary === 'string' && raw.summary.length <= 500 && typeof raw.output === 'string' && raw.output.length <= 4000
        ? { type: 'checkResult', stepId: raw.stepId, passed: raw.passed, kind: 'Practice', summary: raw.summary, output: raw.output } : undefined;
    case 'error':
      return exactKeys(raw, ['type', 'code', 'message']) && typeof raw.code === 'string' && ERROR_CODES.has(raw.code)
        && typeof raw.message === 'string' && raw.message.length <= 500
        ? { type: 'error', code: raw.code, message: raw.message } : undefined;
    case 'sessionClosed':
      return exactKeys(raw, ['type']) ? { type: 'sessionClosed' } : undefined;
    default:
      return undefined;
  }
}

function needId(v: string, what: string): string {
  if (!isId(v)) throw new Error(`Invalid ${what}`);
  return v;
}

export const requests = {
  hello(sessionId: string, extVersion: string): ExtRequest {
    if (!SESSION_RE.test(sessionId) || !SEMVER_RE.test(extVersion)) throw new Error('Invalid hello');
    return { type: 'hello', protocol: PROTOCOL_VERSION, sessionId, extVersion };
  },
  getLabState: (): ExtRequest => ({ type: 'getLabState' }),
  runCheck: (stepId: string): ExtRequest => ({ type: 'runCheck', stepId: needId(stepId, 'step id') }),
  goStep: (stepId: string): ExtRequest => ({ type: 'goStep', stepId: needId(stepId, 'step id') }),
  finishLab: (): ExtRequest => ({ type: 'finishLab' }),
};

/** Re-validate a request object before it goes on the wire. */
export function checkRequest(r: ExtRequest): ExtRequest {
  switch (r.type) {
    case 'hello': return requests.hello(r.sessionId, r.extVersion);
    case 'getLabState': return requests.getLabState();
    case 'runCheck': return requests.runCheck(r.stepId);
    case 'goStep': return requests.goStep(r.stepId);
    case 'finishLab': return requests.finishLab();
    default: throw new Error('Unknown request');
  }
}

export function encodeFrame(message: object): Buffer {
  const body = Buffer.from(JSON.stringify(message), 'utf8');
  if (body.length === 0 || body.length > MAX_FRAME_BYTES) throw new ProtocolError('Message is too large');
  const head = Buffer.alloc(4);
  head.writeUInt32BE(body.length);
  return Buffer.concat([head, body]);
}

export class FrameDecoder {
  private buf: Buffer = Buffer.alloc(0);
  private failed = false;

  push(chunk: Buffer): unknown[] {
    if (this.failed) throw new ProtocolError('Connection already failed');
    this.buf = Buffer.concat([this.buf, chunk]);
    const out: unknown[] = [];
    while (this.buf.length >= 4) {
      const len = this.buf.readUInt32BE(0);
      if (len === 0 || len > MAX_FRAME_BYTES) { this.failed = true; throw new ProtocolError('Invalid message length'); }
      if (this.buf.length < 4 + len) break;
      const body = this.buf.subarray(4, 4 + len);
      this.buf = this.buf.subarray(4 + len);
      try { out.push(JSON.parse(body.toString('utf8'))); } catch { this.failed = true; throw new ProtocolError('Message is not valid JSON'); }
    }
    return out;
  }
}
