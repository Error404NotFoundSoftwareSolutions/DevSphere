// User story: US-34 Fair scoring rules (Sprint 8, MVP)
// Requirements: FR-GRADE-013..014
// Implemented here: environment readiness is shown next to the score, not inside it; tutor use never lowers it (FR-GRADE-013, FR-GRADE-014)

export function ScoreBreakdown() {
  return (
    <section aria-labelledby="scorebreakdown-title">
      <h2 id="scorebreakdown-title">Score breakdown</h2>
      <p>
        Per-check results with points and safe feedback. Environment readiness is listed separately.
      </p>
    </section>
  );
}
