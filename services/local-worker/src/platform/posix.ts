// User story: US-14 Work on Windows and a second OS (Sprint 3, MVP)
// Requirements: NFR-PORT-001..003, NFR-PORT-005
// Implemented here: Linux and macOS specifics

export const lookupArgs = (tool: string) => ["which", tool];
// On POSIX the child runs in its own process group so we can stop the whole group.
export const killGroup = (pid: number) => process.kill(-pid, "SIGTERM");
