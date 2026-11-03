// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: choose which files go to verified grading; secrets and ignored paths are excluded by default (FR-GRADE-004)

const EXCLUDED = [
  /(^|\/)\.env(\..*)?$/,
  /(^|\/)\.git(\/|$)/,
  /(^|\/)node_modules(\/|$)/,
  /(^|\/)\.venv(\/|$)/,
  /(^|\/)__pycache__(\/|$)/,
  /\.(pem|key)$/,
  /(^|\/)id_(rsa|ed25519)$/,
];

export function shouldInclude(relPath: string): boolean {
  const p = relPath.replaceAll("\\", "/");
  return !EXCLUDED.some((re) => re.test(p));
}

export function selectFiles(all: string[]) {
  return { files: all.filter(shouldInclude), excluded: all.filter((f) => !shouldInclude(f)) };
}

export async function previewSnapshot(req: { attemptId: string }) {
  void req; // TODO (Sprint 7): list the real workspace files, enforce size and type limits
  return selectFiles([]);
}
