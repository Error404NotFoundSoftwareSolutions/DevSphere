// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: the ONLY way the worker starts a process: executable + argument array + validated working directory

import { spawn } from "node:child_process";
import { realpathSync } from "node:fs";
import path from "node:path";
import { killTreeArgs } from "../platform/windows";

export type RunResult = {
  exitCode: number | null;
  output: string;
  truncated: boolean;
  timedOut: boolean;
};

// The working directory must be inside the workspace root, after resolving links.
export function resolveInside(root: string, requested: string): string {
  const realRoot = realpathSync(root);
  const resolved = realpathSync(path.resolve(realRoot, requested));
  const rel = path.relative(realRoot, resolved);
  if (rel.startsWith("..") || path.isAbsolute(rel))
    throw new Error("Folder is outside the lab workspace.");
  return resolved;
}

export function runProcess(
  exe: string,
  args: string[],
  opts: { cwd: string; timeoutMs: number; maxOutput?: number },
): Promise<RunResult> {
  const maxOutput = opts.maxOutput ?? 200_000;
  return new Promise((resolve) => {
    // shell: false means "; rm -rf" in an argument is just text (FR-EXEC-002).
    const child = spawn(exe, args, {
      cwd: opts.cwd,
      shell: false,
      windowsHide: true,
      detached: process.platform !== "win32",
    });
    let output = "";
    let truncated = false;
    let timedOut = false;
    const take = (b: Buffer) => {
      if (output.length < maxOutput) output += b.toString();
      else truncated = true;
    };
    child.stdout?.on("data", take);
    child.stderr?.on("data", take);
    const stop = () => {
      // Stop the process and its children (FR-EXEC-005).
      if (process.platform === "win32") {
        const [cmd, ...a] = killTreeArgs(child.pid ?? 0);
        spawn(cmd!, a, { shell: false });
      } else if (child.pid) process.kill(-child.pid, "SIGKILL");
    };
    const timer = setTimeout(() => {
      timedOut = true;
      stop();
    }, opts.timeoutMs);
    child.on("error", (e) => {
      clearTimeout(timer);
      resolve({ exitCode: null, output: String(e), truncated, timedOut });
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      resolve({ exitCode: code, output: output.slice(0, maxOutput), truncated, timedOut });
    });
  });
}
