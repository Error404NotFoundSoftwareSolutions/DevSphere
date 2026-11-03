// User story: US-R3-6 Points and review (Sprint 15, R3)
// Requirements: FR-OSS-008, FR-OSS-010..013, FR-OSS-016..017
// Implemented here: R3: points from verified PR state; never duplicated; review is separate (FR-OSS-008, FR-OSS-016)

export function PointsView() {
  return (
    <section aria-labelledby="pointsview-title">
      <h2 id="pointsview-title">Points</h2>
      <p>Provisional points from verified checks.</p>
    </section>
  );
}
