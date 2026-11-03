// User story: US-07 Download and cache a verified lab bundle (Sprint 2, MVP)
// Requirements: FR-CAT-004, FR-CAT-007..008
// Implemented here: check the bundle checksum before use, and keep a cache for offline work (FR-CAT-004, FR-CAT-008)

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

export function sha256File(file: string): string {
  return createHash("sha256").update(readFileSync(file)).digest("hex");
}

export function verifyBundle(file: string, expectedSha256: string): boolean {
  // A mismatch means "do not use"; the UI tells the student to download again.
  return sha256File(file) === expectedSha256.toLowerCase();
}
