// Capability: CAP-COURSE-PLAYER. Rules: SEC-21 (validate postMessage both ways), SEC-26. Tests: TC-SEC-19-xx.
// Implemented here: strict allow-list parser for messages coming from a webview (untrusted renderer).
import { isId } from './ids';

export type WebviewMessage =
  | { type: 'checkStep'; stepId: string }
  | { type: 'goStep'; stepId: string }
  | { type: 'openHome' }
  | { type: 'finish' };

function onlyKeys(obj: Record<string, unknown>, keys: string[]): boolean {
  const own = Object.keys(obj);
  return own.length === keys.length && keys.every((k) => own.includes(k));
}

export function parseMessage(raw: unknown): WebviewMessage | undefined {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return undefined;
  const m = raw as Record<string, unknown>;
  switch (m.type) {
    case 'checkStep':
      return onlyKeys(m, ['type', 'stepId']) && isId(m.stepId) ? { type: 'checkStep', stepId: m.stepId } : undefined;
    case 'goStep':
      return onlyKeys(m, ['type', 'stepId']) && isId(m.stepId) ? { type: 'goStep', stepId: m.stepId } : undefined;
    case 'openHome':
      return onlyKeys(m, ['type']) ? { type: 'openHome' } : undefined;
    case 'finish':
      return onlyKeys(m, ['type']) ? { type: 'finish' } : undefined;
    default:
      return undefined;
  }
}
