// User story: US-17 Stay in control of what runs (Sprint 4, MVP)
// Requirements: FR-EXEC-004, FR-EXEC-007, FR-EXEC-008
// Implemented here: approval registry for privileged and tutor-suggested actions

final Map<String, bool> _approvals = {};

void registerApproval(String approvalId, bool approved) {
  _approvals[approvalId] = approved;
}

bool isApproved(String approvalId) {
  return _approvals[approvalId] ?? false;
}

