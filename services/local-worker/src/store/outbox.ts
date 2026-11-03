// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: events wait here until the server confirms them (at-least-once delivery: FR-PROG-004)

import type Database from "better-sqlite3";

export type OutboxEvent = { event_id: string; body: string };
export type OutboxLike = {
  pending(limit: number): OutboxEvent[];
  ack(ids: string[]): void;
  count(): number;
};

export function sqliteOutbox(db: Database.Database): OutboxLike {
  return {
    pending: (limit) =>
      db
        .prepare("SELECT event_id, body FROM outbox ORDER BY created_at LIMIT ?")
        .all(limit) as OutboxEvent[],
    ack: (ids) => {
      const del = db.prepare("DELETE FROM outbox WHERE event_id = ?");
      db.transaction(() => ids.forEach((i) => del.run(i)))();
    },
    count: () => (db.prepare("SELECT COUNT(*) AS n FROM outbox").get() as { n: number }).n,
  };
}
