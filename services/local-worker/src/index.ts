// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: the worker's message loop: every request is validated against the IPC contract before any handler runs

import { parseRequest, IpcError } from "@devsphere/ipc-contract";
import { handlers } from "./handlers";

type ParentPort = {
  on(event: "message", cb: (e: { data: unknown }) => void): void;
  postMessage(m: unknown): void;
};
const port = (process as unknown as { parentPort: ParentPort }).parentPort;

port.on("message", async ({ data }) => {
  const { id, channel, payload } = data as { id: string; channel: string; payload: unknown };
  try {
    const request = parseRequest(channel, payload); // rejects unknown channels and extra fields
    const handler = handlers[channel as keyof typeof handlers];
    if (!handler) throw new IpcError("unknown_channel", `No handler for ${channel}`);
    port.postMessage({
      id,
      ok: true,
      result: await (handler as (r: unknown) => Promise<unknown>)(request),
    });
  } catch (err) {
    const e = err as IpcError;
    // Plain-language error with a recovery hint (NFR-UX-006). Never include stack traces.
    port.postMessage({
      id,
      ok: false,
      error: {
        code: e.code ?? "failed",
        message: e.message,
        recovery: "Try again, or restart the app.",
      },
    });
  }
});
