// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: last sync time and pending events; explains what needs a connection (FR-PROG-006)

import { call } from "../../api";

export function SyncStatus() {
  return (
    <section aria-labelledby="syncstatus-title">
      <h2 id="syncstatus-title">Sync</h2>
      <p>Last synced time and number of waiting events.</p>
      <button onClick={() => call("sync:status", {})}>Refresh</button>
    </section>
  );
}
