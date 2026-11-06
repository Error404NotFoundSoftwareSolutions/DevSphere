# Capability: AI gateway (docs/buildathon/PLAN.md). Rules: SEC-01, SEC-10, AIR-02, AIR-06..AIR-09, ADR-007
# Tests: TC-AI-01..06
# Implemented here: the ONE port every AI feature uses to reach a model. Default is a fake that never calls
# out. Gemini is used only when configured, and errors never leak details (keys, quota text) to callers.

from typing import Protocol

from app.core.settings import settings


class ProviderDown(Exception):
    """The model could not answer. The message is safe to show."""


class AiConfigError(Exception):
    """The AI provider is not configured correctly. Fail closed."""


class AiOutputInvalid(Exception):
    """The model answered, but its output did not pass our checks."""


class ModelProvider(Protocol):
    def generate_json(self, *, system: str, prompt: str, schema: dict, max_output_tokens: int = 4000) -> str: ...

    def generate_text(self, *, system: str, prompt: str, max_output_tokens: int = 800) -> str: ...


class FakeProvider:
    """Scripted answers for tests and offline development. Records every call."""

    DEFAULT_TEXT = "Starter answer: think about what the test expects, then try a smaller step."

    def __init__(self, json_responses: list[str] | None = None, text_responses: list[str] | None = None):
        self._json = list(json_responses or [])
        self._text = list(text_responses or [])
        self.calls: list[dict] = []

    def generate_json(self, *, system: str, prompt: str, schema: dict, max_output_tokens: int = 4000) -> str:
        self.calls.append({"kind": "json", "system": system, "prompt": prompt})
        return self._json.pop(0) if self._json else "{}"

    def generate_text(self, *, system: str, prompt: str, max_output_tokens: int = 800) -> str:
        self.calls.append({"kind": "text", "system": system, "prompt": prompt})
        return self._text.pop(0) if self._text else self.DEFAULT_TEXT


_current: ModelProvider | None = None


def set_provider(p: ModelProvider | None) -> None:
    global _current
    _current = p


def build_provider() -> ModelProvider:
    name = settings.ai_provider
    if name == "fake":
        return FakeProvider()
    if name == "gemini":
        raw = settings.gemini_api_key
        key = raw.get_secret_value() if hasattr(raw, "get_secret_value") else str(raw or "")
        if not settings.gemini_project and not key:
            raise AiConfigError("Gemini needs a Google Cloud project or an API key in the environment.")
        from app.ai.gemini import GeminiProvider

        return GeminiProvider(
            model_fast=settings.gemini_model_fast,
            model_pro=settings.gemini_model_pro,
            project=settings.gemini_project,
            location=settings.gemini_location,
            api_key=key,
        )
    raise AiConfigError(f"Unknown AI provider: {name!r}")


def get_provider() -> ModelProvider:
    global _current
    if _current is None:
        _current = build_provider()
    return _current
