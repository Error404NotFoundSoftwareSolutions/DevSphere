// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: the terminal the platform owns, so managed tasks can be recorded (FR-WS-002, FR-EXEC-004)

import * as pty from "node-pty";

// Only terminals opened here are "managed". Other terminals are not observed, and the UI says so.
export function openTerminal(cwd: string, onData: (chunk: string) => void) {
  const shell = process.platform === "win32" ? "powershell.exe" : (process.env.SHELL ?? "bash");
  const term = pty.spawn(shell, [], { name: "xterm-256color", cols: 80, rows: 24, cwd });
  term.onData(onData);
  return term;
}
