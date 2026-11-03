# User story: US-25 AI through a protected proxy with limits (Sprint 6, MVP)
# Requirements: FR-AI-002..003, FR-AI-013, FR-AI-015, NFR-COST-002, NFR-SEC-015
# User story: US-27 Keep working when AI is down (Sprint 6, MVP)
# Requirements: FR-AI-010..011
# Implemented here: the single place that calls the AI provider; swap or add providers here (TBD-03)


class ProviderDown(Exception):
    pass


def ask_model(prompt: str) -> str:
    # TODO (Sprint 6): call the chosen provider with a timeout and a spending cap (NFR-COST-002).
    return "Starter answer: think about what the test expects, then try a smaller step."
