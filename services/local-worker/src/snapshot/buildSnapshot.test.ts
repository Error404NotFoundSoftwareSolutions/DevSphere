// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: TC-FR-GRADE-004-02: .env and key files are excluded by default

import { describe, expect, it } from "vitest";
import { selectFiles } from "./buildSnapshot";

describe("TC-FR-GRADE-004-02 snapshot contents", () => {
  it("excludes secret-bearing and ignored paths", () => {
    const r = selectFiles([
      "app.py",
      ".env",
      ".env.local",
      "keys/server.pem",
      ".git/config",
      "src/id_rsa",
      "tests/test_app.py",
    ]);
    expect(r.files).toEqual(["app.py", "tests/test_app.py"]);
    expect(r.excluded.length).toBe(5);
  });
});
