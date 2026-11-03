// User story: US-R3-1 Check Git readiness (Sprint 13, R3)
// Requirements: FR-GIT-001..005
// Implemented here: R3: three separate readiness items: identity, transport authentication, platform authorisation (FR-GIT-003, BR-10)

export type GitReadiness = { identity: boolean; transport: boolean; platformApp: boolean };

// Never ask the student to paste a token or private key (FR-GIT-005).
export async function checkGitReadiness(): Promise<GitReadiness> {
  return { identity: false, transport: false, platformApp: false }; // TODO (R3): git config, gh auth status, GitHub App install
}
