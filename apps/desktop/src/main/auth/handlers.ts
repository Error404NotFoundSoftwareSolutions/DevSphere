// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: auth:signIn / signOut / getSession are handled in main because main owns the session

import { signIn } from "./signIn";
import { clearRefreshToken } from "./sessionStore";

let current: { userId: string; displayName: string } | null = null;

export async function handleAuth(channel: string) {
  if (channel === "auth:signIn") {
    current = await signIn();
    return current;
  }
  if (channel === "auth:signOut") {
    clearRefreshToken();
    current = null;
    return {};
  } // FR-AUTH-006
  return { userId: current?.userId ?? null };
}
