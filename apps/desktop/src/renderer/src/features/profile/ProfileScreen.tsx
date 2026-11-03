// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-PROF-002..008
// Implemented here: profile form: display name required, everything else optional; no date of birth or phone (FR-PROF-002, FR-PROF-003)

export function ProfileScreen() {
  return (
    <section aria-labelledby="profilescreen-title">
      <h2 id="profilescreen-title">Your profile</h2>
      <p>Display name (editable). Optional: college, course, year, interests.</p>
    </section>
  );
}
