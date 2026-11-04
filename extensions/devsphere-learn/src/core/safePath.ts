// Capability: CAP-COURSE-PLAYER. Rules: SEC-04, SEC-07, SEC-26. Tests: TC-SEC-03-xx, TC-LRN-10-xx.
// Implemented here: path confinement and the allow-list of files copied into a learner's lab folder.
import fs from 'node:fs';
import path from 'node:path';

export class PathError extends Error {
  constructor(reason: string) {
    super(`Unsafe path: ${reason}`);
    this.name = 'PathError';
  }
}

function isInside(root: string, candidate: string): boolean {
  const rel = path.relative(root, candidate);
  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}

function nearestExistingRealpath(p: string): string {
  let current = p;
  for (;;) {
    try {
      return fs.realpathSync(current);
    } catch {
      const parent = path.dirname(current);
      if (parent === current) throw new PathError('no existing parent');
      current = parent;
    }
  }
}

/**
 * Resolve `rel` under `root` and prove the result stays inside `root`, including through symlinks.
 * The target itself may not exist yet (for writes). Throws PathError otherwise.
 */
export function safeResolve(root: string, rel: string): string {
  if (typeof rel !== 'string' || rel.length === 0) throw new PathError('empty');
  if (rel.includes('\0')) throw new PathError('NUL byte');
  if (path.isAbsolute(rel) || /^[A-Za-z]:[\\/]/.test(rel) || rel.startsWith('\\')) throw new PathError('absolute');
  const realRoot = fs.realpathSync(root);
  const candidate = path.resolve(realRoot, rel);
  if (candidate === realRoot || !isInside(realRoot, candidate)) throw new PathError('outside root');
  if (!isInside(realRoot, nearestExistingRealpath(candidate))) throw new PathError('link leaves root');
  return candidate;
}

export interface CopyStep {
  from: string; // relative path inside the published lab bundle
  to: string; // relative path inside the learner's lab folder
}

const DENIED_SEGMENTS = new Set(['protected', 'reference']);

/**
 * Decide which published lab files may be copied to the learner. Protected tests and reference
 * solutions must never reach the learner's machine (SEC-04), so any path containing such a
 * segment is dropped, whatever else it looks like. Everything not listed is ignored.
 */
export function selectLabFiles(relPaths: readonly string[]): CopyStep[] {
  const out: CopyStep[] = [];
  for (const raw of relPaths) {
    if (raw.includes('\0') || raw.includes('\\') || raw.startsWith('/') || /^[A-Za-z]:/.test(raw)) continue;
    const segments = raw.split('/');
    if (segments.some((s) => s === '' || s === '.' || s === '..')) continue;
    if (segments.some((s) => DENIED_SEGMENTS.has(s.toLowerCase()))) continue;
    const [top, second] = segments;
    if (raw === 'lab.yaml') out.push({ from: raw, to: '.devsphere/lab.yaml' });
    else if (raw === 'README.md') out.push({ from: raw, to: 'README.md' });
    else if (top === 'guide' && segments.length > 1) out.push({ from: raw, to: `.devsphere/${raw}` });
    else if (top === 'starter' && segments.length > 1) out.push({ from: raw, to: segments.slice(1).join('/') });
    else if (top === 'tests' && second === 'visible' && segments.length > 2) out.push({ from: raw, to: raw });
  }
  return out;
}
