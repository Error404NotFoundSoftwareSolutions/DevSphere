// User story: US-26 Keep secrets and attacks out of prompts (Sprint 6, MVP)
// Requirements: FR-AI-005, FR-AI-009, NFR-SEC-005, NFR-PRIV-003
// Implemented here: shared corpus test: fixtures/secrets/corpus.json is also used by the Python tests

import { describe, expect, it } from "vitest";
import corpus from "../../../fixtures/secrets/corpus.json";
import { redact } from "./index";

describe("TC-FR-AI-005-01 redaction corpus", () => {
  for (const item of corpus.secrets) {
    it(`removes ${item.name}`, () => {
      expect(redact(item.text).text).not.toContain(item.secret);
    });
  }
  for (const item of corpus.clean) {
    it(`leaves clean text alone: ${item.name}`, () => {
      expect(redact(item.text).text).toBe(item.text);
    });
  }
});
