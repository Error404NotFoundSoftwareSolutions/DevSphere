// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: TC-FR-PROG-004-02: a failed send loses nothing; the retry delivers once

import { describe, expect, it } from "vitest";
import { syncOnce } from "./syncClient";

function fakeOutbox() {
  let events = [
    { event_id: "e1", body: "a" },
    { event_id: "e2", body: "b" },
  ];
  return {
    pending: () => events,
    ack: (ids: string[]) => {
      events = events.filter((e) => !ids.includes(e.event_id));
    },
    count: () => events.length,
  };
}

describe("TC-FR-PROG-004-02 at-least-once sync", () => {
  it("keeps events when the send fails, then delivers on retry", async () => {
    const box = fakeOutbox();
    await expect(
      syncOnce(box, async () => {
        throw new Error("offline");
      }),
    ).rejects.toThrow();
    expect(box.count()).toBe(2);
    expect(await syncOnce(box, async () => {})).toBe(2);
    expect(box.count()).toBe(0);
  });
});
