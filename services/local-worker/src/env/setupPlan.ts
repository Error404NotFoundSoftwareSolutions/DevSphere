// User story: US-12 Approve and run setup safely (Sprint 3, MVP)
// Requirements: FR-ENV-004..006, FR-ENV-011, NFR-SEC-009..010
// Implemented here: the plan shown to the student BEFORE anything changes (FR-ENV-004). No step runs without approval

import type { ToolStatus } from "./detect";

export type PlanStep = {
  tool: string;
  what: string;
  why: string;
  source: string;
  needsElevation: boolean;
};

export function buildPlan(items: ToolStatus[]): {
  planId: string;
  steps: string[];
  detail: PlanStep[];
} {
  // A tool that already satisfies the lab is ready and is never reinstalled (FR-ENV-009).
  const detail = items
    .filter((i) => i.status !== "ready")
    .map((i) => ({
      tool: i.tool,
      what: `Install ${i.tool}`,
      why: `The lab needs ${i.tool} to run your code.`,
      source: "Official download (checksum verified)",
      needsElevation: false,
    }));
  return { planId: crypto.randomUUID(), steps: detail.map((d) => d.what), detail };
}
