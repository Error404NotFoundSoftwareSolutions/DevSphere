// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: keyboard helpers for accessibility checks (NFR-UX-004, NFR-UX-005)

// Move focus into a dialog when it opens, and back to the opener when it closes.
export function focusFirst(container: HTMLElement | null) {
  container
    ?.querySelector<HTMLElement>(
      "button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])",
    )
    ?.focus();
}
