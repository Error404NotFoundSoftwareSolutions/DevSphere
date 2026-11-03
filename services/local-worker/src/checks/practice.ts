// User story: US-20 Check my own work locally (Sprint 5, MVP)
// Requirements: FR-GUIDE-006, FR-GUIDE-008
// Implemented here: practice checks run here and are always labelled Practice (FR-GUIDE-006, FR-GRADE-002)

export type PracticeResult = {
  kind: "practice";
  checkId: string;
  passed: boolean;
  message: string;
};

// Never mark a practice result as verified. Official scores come only from the Grader (BR-01, BR-02).
export function practiceResult(checkId: string, passed: boolean, message: string): PracticeResult {
  return { kind: "practice", checkId, passed, message };
}
