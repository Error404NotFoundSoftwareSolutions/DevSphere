// Capability: CAP-COURSE-PLAYER. Rules: SEC-02, SEC-10, SEC-22, SEC-23. Tests: TC-SEC-04-xx, TC-SEC-10-xx, TC-LRN-50-01.
// Implemented here: run the lab's visible tests with no shell, a minimal environment, a timeout and
// an output cap. The learner's code is untrusted: this is a convenience check (Practice), never a score.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import { safeResolve } from './safePath';

export interface Invocation {
  file: string;
  args: string[];
  cwd: string;
}
export interface RunOptions {
  cwd: string;
  env: Record<string, string>;
  timeoutMs: number;
  maxBytes: number;
}
export interface RunResult {
  code: number | null;
  stdout: string;
  stderr: string;
  timedOut: boolean;
  truncated: boolean;
  error?: string;
}

const PYTHON_ALLOW = new Set(['python3', 'python', 'py']);
const ENV_KEEP = ['PATH', 'HOME', 'LANG', 'USERPROFILE', 'SYSTEMROOT', 'TEMP', 'TMP'];

/** Only a handful of harmless variables reach the child process. No tokens, keys or cloud credentials. */
export function minimalEnv(parent: Record<string, string | undefined>): Record<string, string> {
  const env: Record<string, string> = { PYTHONDONTWRITEBYTECODE: '1', PYTHONNOUSERSITE: '1' };
  for (const key of ENV_KEEP) {
    const v = parent[key];
    if (typeof v === 'string') env[key] = v;
  }
  return env;
}

export function buildPytestInvocation(labRoot: string, pythonCommand: string): Invocation {
  if (!PYTHON_ALLOW.has(pythonCommand)) throw new Error('Python command must be python3, python or py');
  const testsDir = 'tests/visible';
  let resolved: string;
  try {
    resolved = safeResolve(labRoot, testsDir);
    if (!fs.statSync(resolved).isDirectory()) throw new Error('not a directory');
  } catch {
    throw new Error('This lab has no tests folder to run');
  }
  return {
    file: pythonCommand,
    args: ['-m', 'pytest', '-q', '--no-header', '-p', 'no:cacheprovider', testsDir],
    cwd: fs.realpathSync(labRoot),
  };
}

export function runLimited(file: string, args: readonly string[], opts: RunOptions): Promise<RunResult> {
  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';
    let used = 0;
    let truncated = false;
    let timedOut = false;
    let settled = false;
    const child = spawn(file, [...args], {
      cwd: opts.cwd,
      env: opts.env,
      shell: false,
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });
    const finish = (r: RunResult): void => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolve(r);
    };
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, opts.timeoutMs);
    const take = (chunk: Buffer, which: 'out' | 'err'): void => {
      const room = opts.maxBytes - used;
      if (room <= 0) {
        truncated = true;
        child.kill('SIGKILL');
        return;
      }
      const piece = chunk.subarray(0, room).toString('utf8');
      used += Math.min(chunk.length, room);
      if (chunk.length > room) {
        truncated = true;
        child.kill('SIGKILL');
      }
      if (which === 'out') stdout += piece;
      else stderr += piece;
    };
    child.stdout.on('data', (c: Buffer) => take(c, 'out'));
    child.stderr.on('data', (c: Buffer) => take(c, 'err'));
    child.on('error', (e: NodeJS.ErrnoException) => finish({ code: null, stdout, stderr, timedOut, truncated, error: `${e.code ?? 'ERROR'}: ${e.message}` }));
    child.on('close', (code) => finish({ code, stdout, stderr, timedOut, truncated }));
  });
}

/** Plain-language summary of a pytest run (what happened and what to do next). */
export function summarisePytest(code: number | null, stdout: string, stderr: string): string {
  const all = `${stdout}\n${stderr}`;
  if (code === null) return 'Could not run the check. Make sure Python is installed, then try again.';
  if (/No module named pytest/i.test(all)) return 'pytest is not installed. Install it with: python3 -m pip install pytest, then check again.';
  if (code === 0) return 'All checks passed.';
  if (code === 1) return 'Some checks did not pass yet. Read the message below, fix your code, and check again.';
  return 'The checks could not finish. Read the message below and try again.';
}
