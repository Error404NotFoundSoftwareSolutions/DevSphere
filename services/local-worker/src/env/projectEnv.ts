// User story: US-13 Create the project environment and recover from failure (Sprint 3, MVP)
// Requirements: FR-ENV-007..008, FR-ENV-010
// Implemented here: create the isolated project environment from the lockfile, then verify it worked (FR-ENV-007, FR-ENV-008)

import { runProcess } from "../exec/safeSpawn";

// Honour the lab lockfile; never resolve new versions silently.
export async function createProjectEnv(projectDir: string): Promise<{ ok: boolean; log: string }> {
  const sync = await runProcess("uv", ["sync", "--frozen"], {
    cwd: projectDir,
    timeoutMs: 300_000,
  });
  if (sync.exitCode !== 0) return { ok: false, log: sync.output };
  // Success is reported only after a harmless check proves it (NFR-REL-002).
  const check = await runProcess("uv", ["run", "python", "--version"], {
    cwd: projectDir,
    timeoutMs: 30_000,
  });
  return { ok: check.exitCode === 0, log: check.output };
}
