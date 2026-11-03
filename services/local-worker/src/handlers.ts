// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: maps each channel to the module that does the work. Add new handlers here

import type { Channel } from "@devsphere/ipc-contract";
import { detectAll } from "./env/detect";
import { buildPlan } from "./env/setupPlan";
import { runTask, stopTask } from "./exec/runTask";
import { respond } from "./exec/approvals";
import { recordProgress } from "./progress/recorder";
import { syncStatus } from "./sync/syncClient";
import { previewSnapshot } from "./snapshot/buildSnapshot";
import { openWorkspace } from "./workspace/openWorkspace";

type Handler = (request: never) => Promise<unknown>;

// Cast once here; the contract has already validated the shape.
const h = <T>(fn: (r: T) => Promise<unknown>) => fn as unknown as Handler;

export const handlers: Partial<Record<Channel, Handler>> = {
  "env:detect": h(async () => ({ items: await detectAll() })),
  "env:plan": h(async () => buildPlan(await detectAll())),
  "workspace:open": h(openWorkspace),
  "task:run": h(runTask),
  "task:stop": h(stopTask),
  "approval:respond": h(respond),
  "progress:record": h(recordProgress),
  "sync:status": h(syncStatus),
  "submission:preview": h(previewSnapshot),
};
