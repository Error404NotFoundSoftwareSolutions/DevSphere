// User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
// Requirements: FR-CAT-005..006
// Implemented here: an attempt keeps the versions it started with; newer versions only create a notice (FR-CAT-005, FR-CAT-006)

export type PinnedAttempt = Readonly<{
  attemptId: string;
  labId: string;
  bundleVersion: string;
  rubricVersion: number;
  evaluatorVersion: string;
}>;

export const pin = (a: PinnedAttempt): PinnedAttempt => Object.freeze({ ...a });

export function newerVersionAvailable(pinned: PinnedAttempt, latestBundleVersion: string): boolean {
  return pinned.bundleVersion !== latestBundleVersion; // starter: use real semver compare in Sprint 2
}
