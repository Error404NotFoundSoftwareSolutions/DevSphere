// User story: US-21 Save and recover my progress (Sprint 5, MVP)
// Requirements: FR-PROG-001..003, NFR-REL-001..002
// Implemented here: progress recording and crash recovery

import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

void recordProgress(
  Database db, {
  required String eventId,
  required String attemptId,
  required String type,
  required Map<String, dynamic> payload,
}) {
  db.execute(
    'INSERT OR REPLACE INTO progress_events (event_id, attempt_id, type, payload, client_time) VALUES (?, ?, ?, ?, ?)',
    [eventId, attemptId, type, jsonEncode(payload), DateTime.now().toIso8601String()],
  );
}

