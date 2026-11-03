// User story: US-R3-2 Safe branch and remote checks (Sprint 13, R3)
// Requirements: FR-GIT-006..009, FR-CAT-011
// Implemented here: R3: validate branch names so they cannot inject options into Git commands (FR-GIT-007)

export function isSafeBranchName(name: string): boolean {
  if (name.startsWith("-") || name.includes("..") || /[\s~^:?*[\\]/.test(name)) return false;
  return /^[A-Za-z0-9._/-]{1,100}$/.test(name);
}
