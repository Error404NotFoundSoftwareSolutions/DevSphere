// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: one place for the words the UI uses for statuses and result types (NFR-UX-003)

enum ResultKind { practice, verified }

enum StatusKind {
  ready,
  missing,
  installing,
  verifying,
  failed,
  passed,
  blocked,
}

String resultLabel(ResultKind kind) {
  // Practice results are never presented as official (BR-02).
  return kind == ResultKind.practice ? 'Practice (unverified)' : 'Verified';
}

String statusLabel(StatusKind s) {
  final name = s.name;
  return name[0].toUpperCase() + name.substring(1);
}

