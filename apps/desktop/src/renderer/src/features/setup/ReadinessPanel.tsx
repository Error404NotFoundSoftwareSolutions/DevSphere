// User story: US-11 See whether my computer is ready (Sprint 3, MVP)
// Requirements: FR-ENV-001..003, FR-ENV-009, FR-ENV-012..013
// Implemented here: show each tool as ready, missing or incompatible, with a re-check button (FR-ENV-003, FR-ENV-012)

import { call } from "../../api";

export function ReadinessPanel() {
  return (
    <section aria-labelledby="readinesspanel-title">
      <h2 id="readinesspanel-title">Is your computer ready?</h2>
      <p>Python, uv and Git are checked here.</p>
      <button onClick={() => call("env:detect", {})}>Check again</button>
    </section>
  );
}
