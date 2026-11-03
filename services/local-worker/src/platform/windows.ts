// User story: US-14 Work on Windows and a second OS (Sprint 3, MVP)
// Requirements: NFR-PORT-001..003, NFR-PORT-005
// Implemented here: Windows specifics

export const lookupArgs = (tool: string) => ["where", tool];
export const killTreeArgs = (pid: number) => ["taskkill", "/pid", String(pid), "/T", "/F"];
