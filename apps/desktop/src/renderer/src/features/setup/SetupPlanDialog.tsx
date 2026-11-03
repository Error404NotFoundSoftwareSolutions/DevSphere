// User story: US-12 Approve and run setup safely (Sprint 3, MVP)
// Requirements: FR-ENV-004..006, FR-ENV-011, NFR-SEC-009..010
// Implemented here: show what will change, why and from where; nothing runs until the student approves (FR-ENV-004, FR-ENV-005)

import { call } from "../../api";

export function SetupPlanDialog() {
  return (
    <section aria-labelledby="setupplandialog-title">
      <h2 id="setupplandialog-title">Setup plan</h2>
      <p>
        List each step with what, why, source, size and whether it needs permission. Buttons:
        Approve, Cancel.
      </p>
      <button onClick={() => call("env:plan", { labId: "python-hello-001" })}>Show plan</button>
    </section>
  );
}
