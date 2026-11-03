// User story: US-17 Stay in control of what runs (Sprint 4, MVP)
// Requirements: FR-EXEC-004, FR-EXEC-007..008
// Implemented here: anything risky, or proposed by the tutor, waits here for the student's decision (FR-EXEC-007, FR-EXEC-008)

type Pending = { resolve: (approved: boolean) => void };
const pending = new Map<string, Pending>();

// The UI shows `description`; execution continues only if the student approves.
export function requestApproval(description: string): {
  approvalId: string;
  decision: Promise<boolean>;
  description: string;
} {
  const approvalId = crypto.randomUUID();
  const decision = new Promise<boolean>((resolve) => pending.set(approvalId, { resolve }));
  return { approvalId, decision, description };
}

export async function respond(req: { approvalId: string; approved: boolean }) {
  pending.get(req.approvalId)?.resolve(req.approved);
  pending.delete(req.approvalId);
  return {};
}
