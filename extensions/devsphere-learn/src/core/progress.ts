// Capability: CAP-COURSE-PLAYER, CAP-BADGES. Rules: TRU-01, TRU-02, SEC-06. Tests: TC-LRN-40-xx.
// Implemented here: local Practice progress. It can NEVER mark a badge earned: only a live,
// server-signed result may do that, and that value is passed in, never read from this file.
import { isId } from './ids';

export type PracticeResult = 'pass' | 'fail';
export interface StepRecord {
  practice: PracticeResult;
  at: string;
}
export interface LabRecord {
  steps: Record<string, StepRecord>;
}
export interface Progress {
  version: 1;
  labs: Record<string, LabRecord>;
}

const TIME_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z$/;

export function emptyProgress(): Progress {
  return { version: 1, labs: {} };
}

/** Parse stored JSON. Anything unexpected resets to empty: the file is untrusted (it can be edited). */
export function parseProgress(raw: unknown): Progress {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return emptyProgress();
  const r = raw as Record<string, unknown>;
  if (r.version !== 1 || typeof r.labs !== 'object' || r.labs === null || Array.isArray(r.labs)) return emptyProgress();
  const labs: Record<string, LabRecord> = {};
  for (const [labId, lab] of Object.entries(r.labs as Record<string, unknown>)) {
    if (!isId(labId) || typeof lab !== 'object' || lab === null) return emptyProgress();
    const stepsRaw = (lab as Record<string, unknown>).steps;
    if (typeof stepsRaw !== 'object' || stepsRaw === null || Array.isArray(stepsRaw)) return emptyProgress();
    const steps: Record<string, StepRecord> = {};
    for (const [stepId, rec] of Object.entries(stepsRaw as Record<string, unknown>)) {
      if (!isId(stepId) || typeof rec !== 'object' || rec === null) return emptyProgress();
      const { practice, at } = rec as Record<string, unknown>;
      if ((practice !== 'pass' && practice !== 'fail') || typeof at !== 'string' || !TIME_RE.test(at)) return emptyProgress();
      steps[stepId] = { practice, at };
    }
    labs[labId] = { steps };
  }
  return { version: 1, labs };
}

export function recordPractice(p: Progress, labId: string, stepId: string, result: PracticeResult, at: string): Progress {
  if (!isId(labId) || !isId(stepId) || !TIME_RE.test(at)) throw new Error('Invalid progress identifiers');
  const lab = p.labs[labId] ?? { steps: {} };
  return {
    version: 1,
    labs: { ...p.labs, [labId]: { steps: { ...lab.steps, [stepId]: { practice: result, at } } } },
  };
}

export function labSummary(p: Progress, labId: string, stepIds: readonly string[]): { passed: number; total: number; complete: boolean } {
  const steps = p.labs[labId]?.steps ?? {};
  const passed = stepIds.filter((id) => steps[id]?.practice === 'pass').length;
  return { passed, total: stepIds.length, complete: stepIds.length > 0 && passed === stepIds.length };
}

export type BadgeState = 'locked' | 'pending-verification' | 'earned';

/** `serverVerified` must come from a live, signed server result, never from local storage. */
export function badgeState(p: Progress, labId: string, stepIds: readonly string[], serverVerified = false): BadgeState {
  if (serverVerified) return 'earned';
  return labSummary(p, labId, stepIds).complete ? 'pending-verification' : 'locked';
}
