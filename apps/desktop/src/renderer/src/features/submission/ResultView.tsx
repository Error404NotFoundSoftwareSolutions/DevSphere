// User story: US-30 Compute official scores on the server (Sprint 7, MVP)
// Requirements: FR-GRADE-001, FR-GRADE-008..011
// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// Implemented here: show the result with its label: Practice (unverified) or Verified (BR-01, BR-02)

import { ResultBadge } from "@devsphere/ui";

export function ResultView({
  kind,
  score,
  max,
}: {
  kind: "practice" | "verified";
  score: number;
  max: number;
}) {
  return (
    <section aria-labelledby="result-title">
      <h2 id="result-title">
        Result <ResultBadge kind={kind} />
      </h2>
      <p>
        {score} / {max}
      </p>
    </section>
  );
}
