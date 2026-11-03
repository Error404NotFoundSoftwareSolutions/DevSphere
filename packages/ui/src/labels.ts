// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: one place for the words the UI uses for statuses and result types (NFR-UX-003)

export type ResultKind = "practice" | "verified";
export type Status =
  "ready" | "missing" | "installing" | "verifying" | "failed" | "passed" | "blocked";

export function resultLabel(kind: ResultKind): string {
  // Practice results are never presented as official (BR-02).
  return kind === "practice" ? "Practice (unverified)" : "Verified";
}

export function statusLabel(s: Status): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
