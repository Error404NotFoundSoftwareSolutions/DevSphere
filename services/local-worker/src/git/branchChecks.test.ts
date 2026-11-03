// User story: US-R3-2 Safe branch and remote checks (Sprint 13, R3)
// Requirements: FR-GIT-006..009, FR-CAT-011
// Implemented here: TC-FR-GIT-007-01

import { describe, expect, it } from "vitest";
import { isSafeBranchName } from "./branchChecks";

describe("TC-FR-GIT-007-01 branch names", () => {
  it("accepts normal names", () => expect(isSafeBranchName("feature/fix-login")).toBe(true));
  it("rejects option-like and odd names", () => {
    for (const bad of ["--upload-pack=evil", "a..b", "has space", "x;rm"])
      expect(isSafeBranchName(bad)).toBe(false);
  });
});
