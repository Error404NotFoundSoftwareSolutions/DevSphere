<!--
User story: SP-02 Sign-in spike (Sprint 0, -)
Requirements: none (spike or pilot)
Implemented here: write the result here when the spike ends
-->

# Sign-in spike (SP-02)

Status: Complete (Resolved with ADR-008)

## Question

Can the Flutter desktop application implement Google sign-in using the system default browser, Authorization Code flow with PKCE, and an ephemeral loopback redirect (127.0.0.1), exchange the code for provider session tokens, and support silent refresh, token revocation, and secure session storage without embedded secrets?

This spike closes **TBD-02** and evaluates against the pass criteria in SAD Section 5.2 and Section 12 (S2).

## What we tried

1. System browser authentication: Verified launching the system default browser with PKCE parameters (`code_challenge`, `code_challenge_method=S256`, `state`, public client ID, identity scopes `openid profile email`) using `url_launcher` (`apps/desktop/lib/features/auth/sign_in_service.dart`). Embedded webviews are strictly avoided per FR-AUTH-001.
2. Loopback redirect listener: Spun up a loopback listener on `127.0.0.1:<ephemeral-port>` to receive the authorization response redirect with `code` and `state`.
3. CSRF & State validation: Validated that returned `state` must match the cryptographic nonce generated at initiation; mismatched or missing `state` parameter is rejected with an error.
4. Error & Cancellation handling: Simulated user closing the browser or cancelling the OAuth consent flow; the loopback server timeout safely catches cancelled flows and surfaces a clean, recoverable error without crash (FR-AUTH-008).
5. Secure storage & Silent refresh: Tested `apps/desktop/lib/features/auth/session_store.dart` wrapping `flutter_secure_storage`. Verified that on Linux (`libsecret`), Windows (Credential Manager), and macOS (Keychain), refresh tokens are persisted securely. Tested fallback behavior when secure storage is missing or weak, ensuring sensitive session material is never persisted in plaintext (FR-AUTH-007).
6. Revocation and sign-out: Verified sign-out flow clearing local secure storage and calling the token revocation endpoint to invalidate the refresh token on the provider/backend (FR-AUTH-006).
7. Server-side role enforcement: Verified in `services/api/app/core/auth.py` that internal user identity is derived from provider subject (`sub`, FR-AUTH-005) and roles are strictly database-controlled, ignoring any client-asserted claims (FR-AUTH-009).

## Pass criteria evaluation (SAD Section 12 / S2)

| Criterion | Target | Outcome | Evidence |
|---|---|---|---|
| **System browser sign-in** | Google sign-in via system default browser; no embedded webviews (FR-AUTH-001) | **PASS** | `apps/desktop/lib/features/auth/sign_in_service.dart` launches external browser using `LaunchMode.externalApplication`. |
| **No embedded secrets** | No OAuth client secret or backend credential in client package (FR-AUTH-002) | **PASS** | Public desktop application client ID used with PKCE (`S256` challenge); no confidential client secret embedded or compiled into binary. |
| **State parameter verification** | Wrong or missing `state` rejected | **PASS** | Cryptographic random `state` generated before launch and validated against loopback callback; mismatch aborts exchange with invalid-state error. |
| **Cancellation & offline handling** | Distinguish cancelled flow, network failure, and timeout (FR-AUTH-008) | **PASS** | Loopback timeout handles browser close/cancel; specific recovery actions displayed without crashing the UI. |
| **OS secure storage & fallback** | Refresh token saved in OS keychain; fallback if weak/absent (FR-AUTH-007) | **PASS** | `apps/desktop/lib/features/auth/session_store.dart` stores in OS-backed secure storage. If OS keyring unavailable, persistence is disabled and session held in memory. |
| **Silent refresh** | Automatic background token refresh before expiry | **PASS** | Refresh token exchanged with identity provider for short-lived access/ID token prior to expiration without user interruption. |
| **Revocation & Sign-out** | Local tokens cleared and session revoked on backend (FR-AUTH-006) | **PASS** | `SessionStore.clear()` purges tokens; provider revocation endpoint called; backend rejects subsequent requests with 401. |
| **Cross-OS parity** | Works across Windows, Linux, and macOS | **PASS** | Native desktop browser launch and platform-backed secure storage verified across all 3 supported operating systems. |

## Decision

Adopt **Authorization Code with PKCE via system default browser and loopback redirect**, with refresh tokens persisted in OS secure storage (`flutter_secure_storage`) and token exchange against the managed identity provider.
Documented in `docs/DECISIONS.md` as **ADR-008**.
This closes **TBD-02** as resolved.
