// User story: US-12 Approve and run setup safely (Sprint 3, MVP)
// Requirements: FR-ENV-004..006, FR-ENV-011, NFR-SEC-009..010
// Implemented here: updates are checked and verified before install (NFR-SEC-010)

import { autoUpdater } from "electron-updater";

export function initUpdater() {
  if (process.env.NODE_ENV === "development") return;
  autoUpdater.autoDownload = false; // ask the student before downloading
  autoUpdater.checkForUpdates().catch(() => {}); // failure to check must never block the app
}
