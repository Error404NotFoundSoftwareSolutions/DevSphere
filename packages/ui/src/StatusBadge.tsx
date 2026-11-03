// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: consistent status words and a visible focus style for keyboard users (NFR-UX-003, NFR-UX-004)

import { statusLabel, type Status } from "./labels";

export function StatusBadge({ status }: { status: Status }) {
  return (
    <span className="status-badge" data-status={status}>
      {statusLabel(status)}
    </span>
  );
}
