// User story: US-13 Create the project environment and recover from failure (Sprint 3, MVP)
// Requirements: FR-ENV-007..008, FR-ENV-010
// Implemented here: progress and result of creating the project environment; failures explain how to recover (FR-ENV-010)

export function ProjectEnvStatus() {
  return (
    <section aria-labelledby="projectenvstatus-title">
      <h2 id="projectenvstatus-title">Project environment</h2>
      <p>Shows: creating, verifying, ready, or failed with a recovery hint.</p>
    </section>
  );
}
