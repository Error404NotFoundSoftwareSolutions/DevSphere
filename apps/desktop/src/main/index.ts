// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: NFR-PERF-001..002
// Implemented here: app start-up: secure window, worker, IPC router; start-up time is measured (NFR-PERF-001)

import { app, BrowserWindow } from "electron";
import { createMainWindow } from "./window";
import { registerIpc } from "./ipc/router";
import { startWorker } from "./worker/client";
import { mark } from "./perf/startupTimer";
import { initUpdater } from "./updater/updater";

mark("process-start");

app.whenReady().then(() => {
  const worker = startWorker();
  registerIpc(worker);
  createMainWindow().once("ready-to-show", () => mark("window-ready"));
  initUpdater();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createMainWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
