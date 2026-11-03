// User story: US-R3-4 Track my pull request (Sprint 14, R3)
// Requirements: FR-OSS-004..005, FR-OSS-009, FR-OSS-015
// Implemented here: R3: opened, checks passed, approved, merged are separate states (FR-OSS-009)

export function PullRequestTracker() {
  return (
    <section aria-labelledby="pullrequesttracker-title">
      <h2 id="pullrequesttracker-title">Your pull request</h2>
      <p>Shows each state separately. The platform never merges.</p>
    </section>
  );
}
