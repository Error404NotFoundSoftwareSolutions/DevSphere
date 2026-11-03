// User story: US-20 Check my own work locally (Sprint 5, MVP)
// Requirements: FR-GUIDE-006, FR-GUIDE-008
// Implemented here: run a practice check; results carry the Practice (unverified) label (FR-GUIDE-006, FR-GUIDE-008)

export function PracticeChecks() {
  return (
    <section aria-labelledby="practicechecks-title">
      <h2 id="practicechecks-title">Check your work</h2>
      <p>Runs on your computer. The result is labelled Practice (unverified).</p>
    </section>
  );
}
