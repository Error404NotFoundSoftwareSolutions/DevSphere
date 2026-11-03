// User story: US-17 Stay in control of what runs (Sprint 4, MVP)
// Requirements: FR-EXEC-004, FR-EXEC-007..008
// Implemented here: asks the student before anything risky or tutor-proposed runs (FR-EXEC-007, FR-EXEC-008)

import { call } from "../../api";

export function ApprovalDialog() {
  return (
    <section aria-labelledby="approvaldialog-title">
      <h2 id="approvaldialog-title">Please confirm</h2>
      <p>Describe exactly what will run. Buttons: Allow, Decline.</p>
      <button onClick={() => call("approval:respond", { approvalId: "x", approved: false })}>
        Decline
      </button>
    </section>
  );
}
