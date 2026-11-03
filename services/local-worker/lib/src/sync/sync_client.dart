// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: at-least-once outbox sync client

abstract class OutboxStore {
  List<Map<String, dynamic>> pending();
  void ack(List<String> eventIds);
  int count();
}

Future<int> syncOnce(
  OutboxStore outbox,
  Future<void> Function(List<Map<String, dynamic>> events) sender,
) async {
  final items = outbox.pending();
  if (items.isEmpty) return 0;

  await sender(items);
  final ids = items.map((e) => e['event_id'] as String).toList();
  outbox.ack(ids);
  return ids.length;
}

