// User story: US-R2-3 Work on a clean copy of buggy code (Sprint 11, R2)
// Requirements: FR-BUG-003..004, FR-EXEC-010, FR-WS-006, FR-GUIDE-009
// Implemented here: R2: give the student a clean copy at the pinned commit, and reset on request (FR-BUG-003, FR-EXEC-010)

import { cpSync, rmSync } from "node:fs";

export function resetWorkspace(starterDir: string, workDir: string) {
  rmSync(workDir, { recursive: true, force: true });
  cpSync(starterDir, workDir, { recursive: true }); // TODO (R2): checkout the pinned commit instead
}
