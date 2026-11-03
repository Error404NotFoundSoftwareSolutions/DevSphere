// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// Implemented here: TC-FR-GRADE-002-01: practice results are labelled unverified

import { describe, expect, it } from "vitest";
import { resultLabel } from "./labels";

describe("TC-FR-GRADE-002-01 result labels", () => {
  it("labels practice results as unverified", () =>
    expect(resultLabel("practice")).toContain("unverified"));
  it("labels verified results", () => expect(resultLabel("verified")).toBe("Verified"));
});
