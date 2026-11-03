// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: every UI call enters here: validate against the contract, then handle in main or forward to the worker

import { ipcMain } from "electron";
import { CHANNELS, parseRequest } from "@devsphere/ipc-contract";
import type { WorkerClient } from "../worker/client";
import { handleAuth } from "../auth/handlers";

export function registerIpc(worker: WorkerClient) {
  for (const channel of CHANNELS) {
    ipcMain.handle(channel, async (_event, payload: unknown) => {
      const request = parseRequest(channel, payload); // rejects unknown fields
      if (channel.startsWith("auth:")) return handleAuth(channel);
      return worker.request(channel, request);
    });
  }
}
