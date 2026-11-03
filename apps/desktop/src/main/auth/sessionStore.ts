// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: keep the refresh token ONLY in OS-backed storage; if that is weak or missing, store nothing (FR-AUTH-007, NFR-SEC-004)

import { app, safeStorage } from "electron";
import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";

const file = () => path.join(app.getPath("userData"), "session.bin");

function secureStorageAvailable(): boolean {
  if (!safeStorage.isEncryptionAvailable()) return false;
  // On Linux, "basic_text" means no real keyring: treat it as unavailable.
  const backend = (
    safeStorage as unknown as { getSelectedStorageBackend?: () => string }
  ).getSelectedStorageBackend?.();
  return backend !== "basic_text";
}

export function saveRefreshToken(token: string): boolean {
  if (!secureStorageAvailable()) return false; // caller asks for sign-in at next start
  writeFileSync(file(), safeStorage.encryptString(token));
  return true;
}

export function loadRefreshToken(): string | null {
  return existsSync(file()) && secureStorageAvailable()
    ? safeStorage.decryptString(readFileSync(file()))
    : null;
}

export function clearRefreshToken(): void {
  rmSync(file(), { force: true });
}
