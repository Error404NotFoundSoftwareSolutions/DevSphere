// User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
// Requirements: FR-CAT-005, FR-CAT-006
// Implemented here: pin attempt to immutable version

class AttemptPin {
  final String attemptId;
  final String labId;
  final String version;

  const AttemptPin(
      {required this.attemptId, required this.labId, required this.version});
}
