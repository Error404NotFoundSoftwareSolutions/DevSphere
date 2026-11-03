// User story: US-05 Backend foundation (technical enabler) (Sprint 1, MVP)
// Requirements: NFR-MAINT-001, NFR-MAINT-004, NFR-MAINT-006, NFR-TEST-003
// Implemented here: a thin client. Types will be generated from the backend OpenAPI document in CI (NFR-MAINT-001)

export type ApiError = { code: string; message: string; recovery: string; correlation_id: string };

export function createClient(baseUrl: string, getToken: () => Promise<string | null>) {
  async function request<T>(
    method: string,
    path: string,
    body?: unknown,
    idempotencyKey?: string,
  ): Promise<T> {
    const token = await getToken();
    const res = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        "content-type": "application/json",
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        // State-changing calls carry an idempotency key so retries are safe (SRS 3.3).
        ...(idempotencyKey ? { "idempotency-key": idempotencyKey } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    if (!res.ok) throw (await res.json()) as ApiError;
    return (await res.json()) as T;
  }
  return {
    get: <T>(path: string) => request<T>("GET", path),
    post: <T>(path: string, body: unknown, key: string) => request<T>("POST", path, body, key),
    put: <T>(path: string, body: unknown, key: string) => request<T>("PUT", path, body, key),
  };
}
