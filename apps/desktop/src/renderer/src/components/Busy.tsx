// User story: US-18 Responsive interface (Sprint 4, MVP)
// Requirements: NFR-PERF-003..004
// Implemented here: show progress for anything slower than 2 seconds so the UI never looks frozen (NFR-PERF-003, NFR-PERF-004)

export function Busy({ label }: { label: string }) {
  return (
    <div role="progressbar" aria-busy="true" aria-label={label}>
      {label}...
    </div>
  );
}
