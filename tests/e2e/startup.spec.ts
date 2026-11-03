// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: NFR-PERF-001..002
// Implemented here: TC-NFR-SEC-003-01 (secure window) and TC-NFR-PERF-001-01 (start-up time)

import { expect, test } from "@playwright/test";
import { launchApp } from "./helpers/launch";

test("TC-NFR-SEC-003-01 the page has no Node access", async () => {
  const app = await launchApp();
  const page = await app.firstWindow();
  expect(
    await page.evaluate(() => typeof (window as unknown as { require?: unknown }).require),
  ).toBe("undefined");
  expect(
    await page.evaluate(() => typeof (window as unknown as { process?: unknown }).process),
  ).toBe("undefined");
  await app.close();
});

test("TC-NFR-PERF-001-01 usable within 10 seconds", async () => {
  const t0 = Date.now();
  const app = await launchApp();
  await (await app.firstWindow()).getByRole("heading").first().waitFor();
  expect(Date.now() - t0).toBeLessThan(10_000);
  await app.close();
});
