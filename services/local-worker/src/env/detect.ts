// User story: US-11 See whether my computer is ready (Sprint 3, MVP)
// Requirements: FR-ENV-001..003, FR-ENV-009, FR-ENV-012..013
// Implemented here: detect each tool and report ready / missing / incompatible

import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);
export type ToolStatus = {
  tool: string;
  status: "ready" | "missing" | "incompatible";
  version?: string;
};

// Minimum versions come from the lab manifest later; fixed here for the starter.
const WANTED: { tool: string; cmd: string; args: string[]; min: string }[] = [
  { tool: "python", cmd: "python3", args: ["--version"], min: "3.12" },
  { tool: "uv", cmd: "uv", args: ["--version"], min: "0.4" },
  { tool: "git", cmd: "git", args: ["--version"], min: "2.30" },
];

export function satisfiesMin(version: string, min: string): boolean {
  const a = version.split(".").map(Number);
  const b = min.split(".").map(Number);
  for (let i = 0; i < b.length; i++) {
    if ((a[i] ?? 0) !== b[i]) return (a[i] ?? 0) > (b[i] ?? 0);
  }
  return true;
}

export async function detectTool(w: (typeof WANTED)[number]): Promise<ToolStatus> {
  try {
    // execFile never uses a shell, so tool names cannot inject commands (FR-EXEC-002).
    const { stdout } = await run(w.cmd, w.args, { timeout: 5000, windowsHide: true });
    const version = /(\d+\.\d+(?:\.\d+)?)/.exec(stdout)?.[1];
    if (!version) return { tool: w.tool, status: "missing" };
    return {
      tool: w.tool,
      status: satisfiesMin(version, w.min) ? "ready" : "incompatible",
      version,
    };
  } catch {
    return { tool: w.tool, status: "missing" };
  }
}

export const detectAll = () => Promise.all(WANTED.map(detectTool));
