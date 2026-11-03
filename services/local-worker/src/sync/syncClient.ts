// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: send pending events; delete them only after the server confirms (FR-PROG-004, NFR-REL-003)

import type { OutboxLike } from "../store/outbox";

export async function syncOnce(
  outbox: OutboxLike,
  send: (events: string[]) => Promise<void>,
): Promise<number> {
  const batch = outbox.pending(100);
  if (batch.length === 0) return 0;
  await send(batch.map((e) => e.body)); // if this throws, nothing is acked: the batch is sent again later
  outbox.ack(batch.map((e) => e.event_id));
  return batch.length;
}

export async function syncStatus() {
  return { lastSyncAt: null as string | null, pending: 0 }; // TODO (Sprint 5): read from the store
}
