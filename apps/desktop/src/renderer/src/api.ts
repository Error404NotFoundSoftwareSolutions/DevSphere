// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: one place where the UI calls the local service

import type { Channel } from "@devsphere/ipc-contract";

export const call = <T = unknown>(channel: Channel, payload: unknown = {}) =>
  window.devsphere.invoke(channel, payload) as Promise<T>;
