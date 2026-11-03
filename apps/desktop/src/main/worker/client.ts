// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: starts the local worker as a separate process and relays validated requests and its events

import { BrowserWindow, utilityProcess } from "electron";
import path from "node:path";
import { EVENTS } from "@devsphere/ipc-contract";

export type WorkerClient = { request(channel: string, payload: unknown): Promise<unknown> };

export function startWorker(): WorkerClient {
  const child = utilityProcess.fork(path.join(__dirname, "worker.js"));
  const waiting = new Map<
    string,
    { resolve: (v: unknown) => void; reject: (e: unknown) => void }
  >();

  child.on(
    "message",
    (m: {
      id?: string;
      ok?: boolean;
      result?: unknown;
      error?: unknown;
      event?: string;
      data?: unknown;
    }) => {
      if (m.event && (EVENTS as readonly string[]).includes(m.event)) {
        BrowserWindow.getAllWindows().forEach((w) => w.webContents.send(m.event!, m.data)); // one-way events to the UI
        return;
      }
      const entry = m.id ? waiting.get(m.id) : undefined;
      if (!entry || !m.id) return;
      waiting.delete(m.id);
      if (m.ok) entry.resolve(m.result);
      else entry.reject(m.error);
    },
  );

  return {
    request: (channel, payload) =>
      new Promise((resolve, reject) => {
        const id = crypto.randomUUID();
        waiting.set(id, { resolve, reject });
        child.postMessage({ id, channel, payload });
      }),
  };
}
