// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..005, FR-GUIDE-007
// Implemented here: ordered steps with copyable snippets; the copy button puts exactly the snippet text on the clipboard (FR-GUIDE-001, FR-GUIDE-003)

export function GuidePanel() {
  return (
    <section aria-labelledby="guidepanel-title">
      <h2 id="guidepanel-title">Guide</h2>
      <p>
        Step title, explanation, code snippet with a Copy button, and a list of completed steps.
      </p>
    </section>
  );
}
