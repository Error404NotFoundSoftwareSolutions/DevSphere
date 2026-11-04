// Capability: CAP-COURSE-PLAYER. Rules: SEC-04, SEC-07, SEC-26. Tests: TC-LRN-10-04..07.
// Implemented here: create the learner's lab folder from a published lab bundle. Only allow-listed
// files are copied (never protected tests or reference solutions), symlinks in the bundle are
// skipped, and existing files are never overwritten so the learner's work is safe.
import fs from 'node:fs';
import path from 'node:path';
import { isId } from '../core/ids';
import { safeResolve, selectLabFiles } from '../core/safePath';

const MAX_FILES = 500;
const MAX_FILE_BYTES = 1024 * 1024;
const MAX_DEPTH = 6;

export function resolveLabsRoot(configured: string, home: string): string {
  const root = configured.trim() === '' ? path.join(home, 'DevSphereLabs') : configured.trim();
  if (!path.isAbsolute(root) || path.parse(root).root === root) throw new Error('The labs folder must be an absolute path and not the disk root');
  return root;
}

function listFiles(root: string): string[] {
  const out: string[] = [];
  const walk = (dir: string, rel: string, depth: number): void => {
    if (depth > MAX_DEPTH) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.isSymbolicLink()) continue;
      const abs = path.join(dir, entry.name);
      const r = rel === '' ? entry.name : `${rel}/${entry.name}`;
      if (entry.isDirectory()) walk(abs, r, depth + 1);
      else if (entry.isFile() && fs.statSync(abs).size <= MAX_FILE_BYTES && out.length < MAX_FILES) out.push(r);
    }
  };
  walk(root, '', 0);
  return out;
}

export function prepareLab(contentRoot: string, labId: string, labsRoot: string): { dest: string } {
  if (!isId(labId)) throw new Error('Invalid lab id');
  const src = safeResolve(contentRoot, labId);
  if (!fs.statSync(src).isDirectory()) throw new Error('Lab not found');
  const dest = path.join(labsRoot, labId);
  fs.mkdirSync(dest, { recursive: true, mode: 0o700 });
  for (const step of selectLabFiles(listFiles(src))) {
    const from = safeResolve(src, step.from);
    const to = safeResolve(dest, step.to);
    fs.mkdirSync(path.dirname(to), { recursive: true });
    try {
      fs.copyFileSync(from, to, fs.constants.COPYFILE_EXCL);
    } catch (e) {
      if ((e as NodeJS.ErrnoException).code !== 'EEXIST') throw e;
    }
  }
  const marker = safeResolve(dest, '.devsphere/lab.json');
  if (!fs.existsSync(marker)) fs.writeFileSync(marker, JSON.stringify({ labId, version: 1 }));
  return { dest };
}
