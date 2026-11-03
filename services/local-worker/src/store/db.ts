// User story: US-21 Save and recover my progress (Sprint 5, MVP)
// Requirements: FR-PROG-001..003, NFR-REL-001..002
// Implemented here: local SQLite: progress, bundle index, outbox. No secrets and no protected material (ADR-010)

import Database from "better-sqlite3";

export function openDb(file: string) {
  const db = new Database(file);
  db.pragma("journal_mode = WAL"); // survives abnormal exit (FR-PROG-003)
  db.exec(`
    CREATE TABLE IF NOT EXISTS progress_events (event_id TEXT PRIMARY KEY, attempt_id TEXT NOT NULL, type TEXT NOT NULL, payload TEXT NOT NULL, client_time TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS outbox (event_id TEXT PRIMARY KEY, body TEXT NOT NULL, created_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS bundle_index (lab_id TEXT, version TEXT, sha256 TEXT, path TEXT, PRIMARY KEY (lab_id, version));
  `);
  return db;
}
