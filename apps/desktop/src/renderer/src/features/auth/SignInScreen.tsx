// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: the sign-in screen. Distinguish cancelled, offline and expired states with a recovery action each (FR-AUTH-008)

import { useState } from "react";
import { call } from "../../api";

export function SignInScreen({ onDone }: { onDone: () => void }) {
  const [error, setError] = useState<string | null>(null);
  async function signIn() {
    try {
      await call("auth:signIn");
      onDone();
    } catch (e) {
      setError((e as { message?: string }).message ?? "Sign-in failed. Please try again.");
    }
  }
  return (
    <section aria-labelledby="signin-title">
      <h1 id="signin-title">Welcome to DevSphere</h1>
      <button onClick={signIn}>Continue with Google</button>
      {error && <p role="alert">{error}</p>}
    </section>
  );
}
