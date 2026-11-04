# Task: Add a backend endpoint

1. Put the route in the right module under `services/api/app/` (auth, profiles, catalogue, attempts, tutor, submissions, scores, operator).
2. Require the verified-token dependency. Read user ID and role from the token, never from the body.
3. State-changing endpoints accept an `Idempotency-Key`.
4. Return the standard error shape (code, message, recovery, correlation_id).
5. Add it to `docs/BACKEND_API.md` and re-generate the client in `packages/api-client`.
6. Add the endpoint to the authorisation matrix test.
