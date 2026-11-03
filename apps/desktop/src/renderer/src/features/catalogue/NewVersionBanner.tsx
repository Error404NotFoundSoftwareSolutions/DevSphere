// User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
// Requirements: FR-CAT-005..006
// Implemented here: tell the student a newer lab version exists; the current attempt stays on its own version (FR-CAT-006)

export function NewVersionBanner() {
  return (
    <section aria-labelledby="newversionbanner-title">
      <h2 id="newversionbanner-title">A newer version of this lab is available</h2>
      <p>Your current attempt keeps its version. You can start a new attempt on the new one.</p>
    </section>
  );
}
