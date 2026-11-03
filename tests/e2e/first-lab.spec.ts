// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// User story: US-19 Follow a step-by-step guide (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..005, FR-GUIDE-007
// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: TC-MVP-JOURNEY-01: sign in, pick the sample lab, follow a step, submit. Skipped until Sprint 7

import { test } from "@playwright/test";

test.skip("student completes the first lab (MVP journey)", async () => {
  // 1 sign in (stubbed identity)  2 open python-hello-001  3 run readiness  4 follow guide step 2
  // 5 run practice check, expect label "Practice (unverified)"  6 submit, expect label "Verified" with a score
});
