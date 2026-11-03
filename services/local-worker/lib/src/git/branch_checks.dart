// User story: US-R3-2 Safe branch and remote checks (Sprint 13, R3)
// Requirements: FR-GIT-006..009, FR-CAT-011
// Implemented here: branch-name validation for contribution flow

final RegExp _safeBranch = RegExp(r'^[a-zA-Z0-9._/-]+$');

bool isSafeBranchName(String name) {
  if (name.isEmpty || name.startsWith('-') || name.startsWith('.')) return false;
  if (name.contains('..') || name.contains(' ') || name.contains(';') || name.contains('~')) {
    return false;
  }
  return _safeBranch.hasMatch(name);
}

