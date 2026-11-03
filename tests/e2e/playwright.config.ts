// User story: US-41 Every requirement has a test record (Sprint 9, MVP)
// Requirements: NFR-TEST-001
// Implemented here: Playwright config for the Electron app. Build first with pnpm build

import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  testMatch: /.*\.spec\.ts/,
  timeout: 60_000,
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"]],
});
