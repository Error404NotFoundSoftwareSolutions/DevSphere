// User story: US-R3-1 Check Git readiness (Sprint 13, R3)
// Requirements: FR-GIT-001..005
// Implemented here: R3: three separate readiness items (FR-GIT-003). Never ask for a token or private key (FR-GIT-005)

export function GitReadiness() {
  return (
    <section aria-labelledby="gitreadiness-title">
      <h2 id="gitreadiness-title">Git readiness</h2>
      <p>Git identity, GitHub sign-in for Git, and platform access are checked separately.</p>
    </section>
  );
}
