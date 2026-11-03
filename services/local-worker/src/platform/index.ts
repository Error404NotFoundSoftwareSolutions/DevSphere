// User story: US-14 Work on Windows and a second OS (Sprint 3, MVP)
// Requirements: NFR-PORT-001..003, NFR-PORT-005
// Implemented here: all OS differences live behind this folder, not in lab content (NFR-PORT-002)

import { lookupArgs as winLookup } from "./windows";
import { lookupArgs as posixLookup } from "./posix";

export type PlatformName = "windows" | "linux" | "macos";

export function currentPlatform(): PlatformName {
  if (process.platform === "win32") return "windows";
  return process.platform === "darwin" ? "macos" : "linux";
}

// Command used to find a tool on PATH, as [executable, ...args].
export function lookupCommand(tool: string): string[] {
  return currentPlatform() === "windows" ? winLookup(tool) : posixLookup(tool);
}
