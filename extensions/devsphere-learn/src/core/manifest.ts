// Capability: CAP-COURSE-PLAYER. Rules: SEC-06, SEC-26, SEC-27. Tests: TC-LRN-20-xx.
// Implemented here: validation of lab.yaml (untrusted input) into a small typed manifest.
import { parse } from 'yaml';
import { isId, isPlainText } from './ids';

export class ManifestError extends Error {
  constructor(reason: string) {
    super(`Invalid lab manifest: ${reason}`);
    this.name = 'ManifestError';
  }
}

export interface LabStep {
  id: string;
  title: string;
  contentRef: string;
  practiceCheck?: string;
}

export interface LabManifest {
  id: string;
  version: string;
  title: string;
  description: string;
  difficulty: string;
  estimatedMinutes: number;
  steps: LabStep[];
}

const MAX_BYTES = 64 * 1024;
const MAX_STEPS = 50;
const REF_RE = /^[A-Za-z0-9][A-Za-z0-9_./-]{0,120}\.md$/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function safeRef(ref: unknown): ref is string {
  return typeof ref === 'string' && REF_RE.test(ref) && !ref.split('/').some((s) => s === '..' || s === '.' || s === '');
}

export function parseLabManifest(text: string): LabManifest {
  if (typeof text !== 'string' || text.length > MAX_BYTES) throw new ManifestError('too large');
  let doc: unknown;
  try {
    doc = parse(text, { maxAliasCount: 0, schema: 'core', strict: true });
  } catch {
    throw new ManifestError('not valid YAML');
  }
  if (!isRecord(doc)) throw new ManifestError('must be a mapping');
  const { id, version, title, description, difficulty, estimated_minutes: minutes, guide } = doc;
  if (!isId(id) || id.length < 3) throw new ManifestError('id');
  if (!isPlainText(version, 32)) throw new ManifestError('version');
  if (!isPlainText(title, 120)) throw new ManifestError('title');
  if (!isPlainText(description, 400)) throw new ManifestError('description');
  if (!isPlainText(difficulty, 32)) throw new ManifestError('difficulty');
  if (typeof minutes !== 'number' || !Number.isInteger(minutes) || minutes < 1 || minutes > 1000) {
    throw new ManifestError('estimated_minutes');
  }
  if (!isRecord(guide) || !Array.isArray(guide.steps) || guide.steps.length === 0 || guide.steps.length > MAX_STEPS) {
    throw new ManifestError('guide.steps');
  }
  const seen = new Set<string>();
  const steps: LabStep[] = [];
  for (const raw of guide.steps as unknown[]) {
    if (!isRecord(raw)) throw new ManifestError('step');
    if (!isId(raw.id) || seen.has(raw.id)) throw new ManifestError('step id');
    if (!isPlainText(raw.title, 120)) throw new ManifestError('step title');
    if (!safeRef(raw.content_ref)) throw new ManifestError('step content_ref');
    if (raw.practice_check !== undefined && !isId(raw.practice_check)) throw new ManifestError('step practice_check');
    seen.add(raw.id);
    const step: LabStep = { id: raw.id, title: raw.title, contentRef: raw.content_ref };
    if (typeof raw.practice_check === 'string') step.practiceCheck = raw.practice_check;
    steps.push(step);
  }
  return { id, version, title, description, difficulty, estimatedMinutes: minutes, steps };
}
