// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: validation used by main and by the worker before any action

import { isChannel } from "./channels";
import { contract } from "./schemas";

export class IpcError extends Error {
  constructor(
    public code: "unknown_channel" | "invalid_request",
    message: string,
  ) {
    super(message);
  }
}

// Returns the parsed request, or throws IpcError. Extra fields are rejected.
export function parseRequest(channel: string, data: unknown): unknown {
  if (!isChannel(channel)) throw new IpcError("unknown_channel", `Unknown channel: ${channel}`);
  const result = contract[channel].request.safeParse(data);
  if (!result.success) throw new IpcError("invalid_request", result.error.message);
  return result.data;
}
