// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: type of the bridge exposed by the preload script

import type { Channel, EventName } from "@devsphere/ipc-contract";

declare global {
  interface Window {
    devsphere: {
      invoke(channel: Channel, payload: unknown): Promise<unknown>;
      on(event: EventName, cb: (data: unknown) => void): () => void;
    };
  }
}
export {};
