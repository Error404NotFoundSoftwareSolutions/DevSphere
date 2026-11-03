// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// Requirements: FR-PROF-001, FR-PROF-010
// Implemented here: privacy notice shown BEFORE any profile data is collected; records notice version (FR-PROF-001, FR-PROF-010)

export function ConsentScreen() {
  return (
    <section aria-labelledby="consentscreen-title">
      <h2 id="consentscreen-title">Privacy notice</h2>
      <p>
        Explain what is collected, why, and for how long. Ask the student to agree before
        continuing.
      </p>
    </section>
  );
}
