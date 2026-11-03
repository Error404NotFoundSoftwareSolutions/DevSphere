// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: run a task declared by the lab, record evidence with secrets removed (FR-EXEC-001, FR-EXEC-003, FR-EXEC-006)

import { redact } from "@devsphere/redaction";
import { runProcess } from "./safeSpawn";

// Tasks come from the lab manifest, never from the UI. Starter table:
const TASKS: Record<string, { exe: string; args: string[] }> = {
  "run-tests": { exe: "uv", args: ["run", "pytest", "-q"] },
};
const running = new Map<string, AbortController>();

export async function runTask(req: { attemptId: string; taskId: string }) {
  const task = TASKS[req.taskId];
  if (!task) throw new Error(`Unknown task: ${req.taskId}`);
  const runId = crypto.randomUUID();
  running.set(runId, new AbortController());
  const startedAt = new Date().toISOString();
  const result = await runProcess(task.exe, task.args, { cwd: process.cwd(), timeoutMs: 60_000 });
  running.delete(runId);
  // Evidence: command, times, exit code, bounded redacted output (FR-EXEC-003).
  const evidence = {
    runId,
    command: [task.exe, ...task.args],
    startedAt,
    endedAt: new Date().toISOString(),
    exitCode: result.exitCode,
    output: redact(result.output).text,
  };
  return { runId, evidence };
}

export async function stopTask(req: { runId: string }) {
  running.get(req.runId)?.abort(); // TODO: connect to the process handle (Sprint 4)
  return {};
}
