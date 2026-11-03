// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: TC-FR-EXEC-002-02: shell characters in arguments stay plain text

import { describe, expect, it } from "vitest";
import { mkdtempSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { resolveInside, runProcess } from "./safeSpawn";

describe("TC-FR-EXEC-002-02 no shell interpretation", () => {
  it("treats metacharacters as literal text", async () => {
    const dir = mkdtempSync(path.join(tmpdir(), "ds-"));
    const evil = `hi; touch ${path.join(dir, "pwned")}`;
    const r = await runProcess(process.execPath, ["-e", "console.log(process.argv[1])", evil], {
      cwd: dir,
      timeoutMs: 10_000,
    });
    expect(r.output).toContain("hi;");
    expect(existsSync(path.join(dir, "pwned"))).toBe(false);
  });
  it("rejects a folder outside the workspace", () => {
    const dir = mkdtempSync(path.join(tmpdir(), "ds-"));
    expect(() => resolveInside(dir, "..")).toThrow();
  });
});
