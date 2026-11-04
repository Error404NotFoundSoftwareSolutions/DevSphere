// Capability: CAP-COURSE-PLAYER. Rules: SEC-07, SEC-26. Tests: TC-SEC-03-xx.
// Implemented here: path confinement for reading guide files from the lab folder.
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
