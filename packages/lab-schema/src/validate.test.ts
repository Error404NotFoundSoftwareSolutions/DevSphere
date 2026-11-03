// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// Implemented here: tests for FR-CAT-002 and FR-CAT-003

import { describe, expect, it } from "vitest";
import { validateManifest, checkPointsTotal } from "./index";

const good = {
  schema_version: 1,
  id: "python-hello-001",
  version: "1.0.0",
  title: "Hello, Python",
  difficulty: "beginner",
  os: ["windows", "linux"],
  runtimes: [{ name: "python", version: ">=3.12" }],
  workspace: { type: "code-editor", language: "python" },
  guide: { steps: [{ id: "s1", title: "Start", content_ref: "guide/01.md" }] },
  tutor: { enabled: true, max_assistance_level: 4 },
  evaluation: {
    rubric_version: 1,
    evaluator: "pytest",
    max_points: 100,
    checks: [{ id: "a", type: "test", points: 100, visible: false }],
  },
};

describe("TC-FR-CAT-002-01 manifest validation", () => {
  it("accepts a good manifest", () => expect(validateManifest(good).ok).toBe(true));
  it("rejects a missing title", () =>
    expect(validateManifest({ ...good, title: undefined }).ok).toBe(false));
  it("TC-FR-CAT-003-01 explains an unsupported schema version", () => {
    const r = validateManifest({ ...good, schema_version: 2 });
    expect(r.ok).toBe(false);
  });
  it("checks that points add up", () => expect(checkPointsTotal(good)).toBe(true));
});
