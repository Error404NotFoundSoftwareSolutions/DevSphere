# User story: US-24 Get hints that teach, not only answers (Sprint 6, MVP)
# Requirements: FR-AI-006..008, FR-AI-016
# User story: US-25 AI through a protected proxy with limits (Sprint 6, MVP)
# Requirements: FR-AI-002..003, FR-AI-013, FR-AI-015, NFR-COST-002, NFR-SEC-015
# Implemented here: hint levels 1 to 6 and the rule that the lab's cap always wins (FR-AI-004, FR-AI-006). Full rules: docs/AI_TUTOR_POLICY.md

LEVELS = {
    1: "Ask a guiding question. Do not give code.",
    2: "Point to the relevant concept or documentation.",
    3: "Describe the approach in words.",
    4: "Show a small similar example, not the solution.",
    5: "Show the faulty line and explain the error.",
    6: "Show a worked solution (only if the lab allows it).",
}


def effective_level(requested: int, lab_cap: int) -> int:
    return max(1, min(requested, lab_cap))


def build_prompt(level: int, question: str, code: str | None) -> str:
    # The system instruction is fixed text. Student text is data, never instructions (FR-AI-008).
    parts = [
        f"You are a patient programming tutor. Rule: {LEVELS[level]}",
        f"<student_question>{question}</student_question>",
    ]
    if code:
        parts.append(f"<student_code>{code}</student_code>")
    return "\n".join(parts)
