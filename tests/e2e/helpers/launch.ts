// User story: US-41 Every requirement has a test record (Sprint 9, MVP)
// Requirements: NFR-TEST-001
// Implemented here: start the built Electron app for a test

import { _electron as electron } from "@playwright/test";
import path from "node:path";

export async function launchApp() {
  return electron.launch({ args: [path.join(__dirname, "../../../apps/desktop")] });
}
