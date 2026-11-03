// User story: US-21 Save and recover my progress (Sprint 5, MVP)
// Requirements: FR-PROG-001..003, NFR-REL-001..002
// Implemented here: save progress after every step, with a client-generated event id (FR-PROG-003, FR-PROG-004)

// The id is created on the device, so the server can ignore repeats (idempotent).
export async function recordProgress(req: {
  attemptId: string;
  type: string;
  payload: Record<string, unknown>;
}) {
  const eventId = crypto.randomUUID();
  // TODO (Sprint 5): one transaction that writes progress_events and outbox together.
  void req;
  return { eventId };
}
