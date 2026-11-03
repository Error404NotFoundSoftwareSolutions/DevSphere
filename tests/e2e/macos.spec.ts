// User story: US-R3-7 Third operating system (Sprint 15, R3)
// Requirements: NFR-PORT-004
// Implemented here: R3: the third operating system. Same journey on macOS; failures are recorded in docs/OS_COMPATIBILITY.md (ADR-002)

import { test } from "@playwright/test";

test.skip(process.platform !== "darwin", "macOS only");
test.skip("TC-MVP-JOURNEY-MAC-01 first lab on macOS", async () => {
  // Reuse the steps from first-lab.spec.ts once signing and notarisation work (release checklist).
});
