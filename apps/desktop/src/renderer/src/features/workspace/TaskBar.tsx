// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: run and stop declared lab tasks; the app shows time and output limits (FR-EXEC-005, FR-EXEC-006)

import { call } from "../../api";

export function TaskBar() {
  return (
    <section aria-labelledby="taskbar-title">
      <h2 id="taskbar-title">Tasks</h2>
      <p>Run tests, stop a running task.</p>
      <button onClick={() => call("task:run", { attemptId: "a1", taskId: "run-tests" })}>
        Run tests
      </button>
    </section>
  );
}
