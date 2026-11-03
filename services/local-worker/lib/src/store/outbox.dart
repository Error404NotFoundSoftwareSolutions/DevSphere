// User story: US-22 Sync progress and work offline (Sprint 5, MVP)
// Requirements: FR-PROG-004..007, NFR-REL-003, NFR-PERF-006..007
// Implemented here: persistent outbox storage using SQLite

import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../sync/sync_client.dart';

class SqliteOutboxStore implements OutboxStore {
  final Database db;

  SqliteOutboxStore(this.db);

  void enqueue(String eventId, Map<String, dynamic> body) {
    db.execute(
      'INSERT OR REPLACE INTO outbox (event_id, body, created_at) VALUES (?, ?, ?)',
      [eventId, jsonEncode(body), DateTime.now().toIso8601String()],
    );
  }

  @override
  List<Map<String, dynamic>> pending() {
    final results = db.select('SELECT event_id, body FROM outbox ORDER BY created_at ASC');
    return results.map((row) {
      return {
        'event_id': row['event_id'] as String,
        'body': jsonDecode(row['body'] as String),
      };
    }).toList();
  }

  @override
  void ack(List<String> eventIds) {
    for (final id in eventIds) {
      db.execute('DELETE FROM outbox WHERE event_id = ?', [id]);
    }
  }

  @override
  int count() {
    final row = db.select('SELECT COUNT(*) as cnt FROM outbox').first;
    return row['cnt'] as int;
  }
}

