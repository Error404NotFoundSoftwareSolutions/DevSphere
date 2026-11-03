// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// Implemented here: the badge that always says whether a result is Practice or Verified

import { resultLabel, type ResultKind } from "./labels";

export function ResultBadge({ kind }: { kind: ResultKind }) {
  return (
    <span data-kind={kind} role="status">
      {resultLabel(kind)}
    </span>
  );
}
