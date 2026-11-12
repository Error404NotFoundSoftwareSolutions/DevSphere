// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: TC-FR-PROG-004-02: a failed send loses nothing; the retry delivers once

import 'package:test/test.dart';
import 'package:local_worker/src/sync/sync_client.dart';

class FakeOutbox implements OutboxStore {
  List<Map<String, dynamic>> events = [
    {'event_id': 'e1', 'body': 'a'},
    {'event_id': 'e2', 'body': 'b'},
  ];

  @override
  List<Map<String, dynamic>> pending() => List.from(events);

  @override
  void ack(List<String> ids) {
    events = events.where((e) => !ids.contains(e['event_id'])).toList();
  }

  @override
  int count() => events.length;
}

void main() {
  group('TC-FR-PROG-004-02 at-least-once sync', () {
    test('keeps events when the send fails, then delivers on retry', () async {
      final box = FakeOutbox();
      expect(
        syncOnce(box, (_) async => throw Exception('offline')),
        throwsA(isA<Exception>()),
      );
      expect(box.count(), equals(2));
      expect(await syncOnce(box, (_) async {}), equals(2));
      expect(box.count(), equals(0));
    });
  });
}
