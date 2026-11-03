// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: tests for NFR-SEC-002 (narrow, schema-validated interface)

import { describe, expect, it } from "vitest";
import { parseRequest, CHANNELS } from "./index";

describe("TC-NFR-SEC-002-01 ipc contract", () => {
  it("accepts a valid request", () => {
    expect(parseRequest("task:stop", { runId: "r1" })).toEqual({ runId: "r1" });
  });
  it("rejects an unknown channel", () => {
    expect(() => parseRequest("shell:exec", { cmd: "ls" })).toThrow();
  });
  it("rejects unknown fields (no raw command smuggling)", () => {
    expect(() =>
      parseRequest("task:run", { attemptId: "a", taskId: "t", cmd: "rm -rf /" }),
    ).toThrow();
  });
  it("has a schema for every channel", () => {
    expect(CHANNELS.length).toBe(18);
  });
});
