// User story: US-01 Sign in with Google (Sprint 1, MVP)
// Requirements: FR-AUTH-001..009, NFR-SEC-004, NFR-SEC-006
// Implemented here: Google sign-in in the system browser with PKCE and a loopback redirect. Details are confirmed by spike SP-02 (FR-AUTH-001, FR-AUTH-002)

import { createHash, randomBytes } from "node:crypto";
import http from "node:http";
import { shell } from "electron";

const b64url = (b: Buffer) => b.toString("base64url");
export const newVerifier = () => b64url(randomBytes(32));
export const challengeFor = (verifier: string) =>
  b64url(createHash("sha256").update(verifier).digest());

// Wait on 127.0.0.1 for the browser redirect. The state value must match (protects against forged callbacks).
function waitForCode(
  expectedState: string,
): Promise<{ redirectUri: string; code: Promise<string> }> {
  return new Promise((resolveServer) => {
    let resolveCode!: (c: string) => void;
    let rejectCode!: (e: Error) => void;
    const code = new Promise<string>((res, rej) => {
      resolveCode = res;
      rejectCode = rej;
    });
    const server = http.createServer((req, res) => {
      const url = new URL(req.url ?? "/", "http://127.0.0.1");
      res.end("You can close this window and return to DevSphere.");
      server.close();
      if (url.searchParams.get("state") !== expectedState)
        return rejectCode(new Error("Sign-in was not recognised. Please try again."));
      if (url.searchParams.get("error")) return rejectCode(new Error("Sign-in was cancelled.")); // FR-AUTH-008
      resolveCode(url.searchParams.get("code") ?? "");
    });
    server.listen(0, "127.0.0.1", () => {
      const port = (server.address() as { port: number }).port;
      resolveServer({ redirectUri: `http://127.0.0.1:${port}/callback`, code });
    });
  });
}

export async function signIn(): Promise<{ userId: string; displayName: string }> {
  const verifier = newVerifier();
  const state = b64url(randomBytes(16));
  const { redirectUri, code } = await waitForCode(state);
  const params = new URLSearchParams({
    response_type: "code",
    scope: "openid profile email",
    code_challenge_method: "S256",
    code_challenge: challengeFor(verifier),
    state,
    redirect_uri: redirectUri,
  });
  await shell.openExternal(
    `https://accounts.google.com/o/oauth2/v2/auth?${params}&client_id=${process.env.GOOGLE_DESKTOP_CLIENT_ID ?? ""}`,
  );
  await code;
  // TODO (Sprint 1): exchange the code with the verifier, then sign in with the identity provider's credential call.
  return { userId: "todo", displayName: "Student" };
}
