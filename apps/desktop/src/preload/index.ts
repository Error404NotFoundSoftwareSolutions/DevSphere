// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: the only bridge to the page: invoke an allow-listed channel, subscribe to an allow-listed event

import { contextBridge, ipcRenderer } from "electron";
import { CHANNELS, EVENTS } from "@devsphere/ipc-contract";

contextBridge.exposeInMainWorld("devsphere", {
  invoke(channel: string, payload: unknown) {
    if (!(CHANNELS as readonly string[]).includes(channel))
      throw new Error(`Blocked channel: ${channel}`);
    return ipcRenderer.invoke(channel, payload);
  },
  on(event: string, cb: (data: unknown) => void) {
    if (!(EVENTS as readonly string[]).includes(event)) throw new Error(`Blocked event: ${event}`);
    const listener = (_e: unknown, data: unknown) => cb(data);
    ipcRenderer.on(event, listener);
    return () => ipcRenderer.removeListener(event, listener);
  },
});
