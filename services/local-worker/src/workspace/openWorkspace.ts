// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: create or open the student's project folder (a normal, user-visible folder: NFR-MAINT-005)

import { mkdirSync } from "node:fs";
import os from "node:os";
import path from "node:path";

export async function openWorkspace(req: { attemptId: string }) {
  const dir = path.join(os.homedir(), "DevSphere", req.attemptId);
  mkdirSync(dir, { recursive: true });
  return { ok: true, dir };
}
