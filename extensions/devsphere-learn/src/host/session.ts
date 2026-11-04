// Capability: CAP-APP-EXT-CHANNEL (ADR-019). Rules: SEC-24, SEC-26. Threats T19, T20. Tests: TC-CMP-10-xx
// Implemented here: find the worker's session for THIS lab folder, trusting only private files: the
// runtime directory and the session file must belong to the current user and be closed to everyone
// else, the file must not be a symlink, and its content is validated.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { isId } from '../core/ids';

export interface SessionInfo {
  sessionId: string;
  socketPath: string;
  labId: string;
  labRoot: string;
  protocol: 1;
}

export function defaultRuntimeDir(env: NodeJS.ProcessEnv = process.env, home: string = os.homedir()): string {
  const xdg = env.XDG_RUNTIME_DIR;
  if (xdg && path.isAbsolute(xdg)) return path.join(xdg, 'buildloop');
  return path.join(home, '.buildloop', 'run');
}

const FILE_RE = /^session-([a-f0-9]{32})\.json$/;
const MAX_BYTES = 4096;

function mine(st: fs.Stats): boolean {
  return typeof process.getuid !== 'function' || st.uid === process.getuid();
}
function closedToOthers(st: fs.Stats): boolean {
  return process.platform === 'win32' || (st.mode & 0o077) === 0;
}
function real(p: string): string | undefined {
  try { return fs.realpathSync(p); } catch { return undefined; }
}

export function discoverSession(workspaceRoot: string, runtimeDir: string): SessionInfo | undefined {
  let dirStat: fs.Stats;
  try { dirStat = fs.lstatSync(runtimeDir); } catch { return undefined; }
  if (!dirStat.isDirectory() || !mine(dirStat) || !closedToOthers(dirStat)) return undefined;
  const realRuntime = real(runtimeDir);
  const realWorkspace = real(workspaceRoot);
  if (!realRuntime || !realWorkspace) return undefined;
  for (const name of fs.readdirSync(runtimeDir)) {
    const m = FILE_RE.exec(name);
    if (!m) continue;
    const file = path.join(runtimeDir, name);
    try {
      const st = fs.lstatSync(file);
      if (!st.isFile() || st.isSymbolicLink() || !mine(st) || !closedToOthers(st) || st.size > MAX_BYTES) continue;
      const j = JSON.parse(fs.readFileSync(file, 'utf8')) as Record<string, unknown>;
      const { sessionId, socketPath, labId, labRoot, protocol } = j;
      if (sessionId !== m[1] || typeof socketPath !== 'string' || !isId(labId) || typeof labRoot !== 'string' || protocol !== 1) continue;
      if (!path.isAbsolute(socketPath) || real(path.dirname(socketPath)) !== realRuntime) continue;
      if (real(labRoot) !== realWorkspace) continue;
      return { sessionId: m[1] as string, socketPath, labId, labRoot, protocol: 1 };
    } catch {
      continue;
    }
  }
  return undefined;
}
