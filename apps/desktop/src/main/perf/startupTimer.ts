// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: NFR-PERF-001..002
// Implemented here: measure start-up so NFR-PERF-001 (usable within 10 s on the reference machine) can be tested

const marks = new Map<string, number>();
export const mark = (name: string) => marks.set(name, Date.now());
export const elapsed = (from: string, to: string) => (marks.get(to) ?? 0) - (marks.get(from) ?? 0);
