# Capability: AI gateway (docs/buildathon/PLAN.md). Rules: SEC-01, SEC-22, AIR-02, AIR-07. Tests: TC-AI-04..05
# Implemented here: the Google Gemini adapter (google-genai SDK). On Google Cloud it uses the service identity
# through Vertex AI, so no key exists. With an API key (local development) it uses the Gemini API. SDK errors
# are turned into a plain ProviderDown: their text can contain request details, so it is never passed on.
# NOT yet exercised against the live service from this repository's tests (they use a stand-in SDK).

from app.ai.provider import ProviderDown

TIMEOUT_MS = 45_000


class GeminiProvider:
    def __init__(self, *, model_fast: str, model_pro: str, project: str, location: str, api_key: str):
        self.model_fast = model_fast
        self.model_pro = model_pro
        self._project = project
        self._location = location
        self._api_key = api_key
        self._client = None

    def _sdk(self):
        import google.genai as genai
        from google.genai import types

        return genai, types

    def _get_client(self):
        if self._client is None:
            genai, types = self._sdk()
            kwargs: dict = {}
            if hasattr(types, "HttpOptions"):
                kwargs["http_options"] = types.HttpOptions(timeout=TIMEOUT_MS)
            if self._api_key:
                kwargs["api_key"] = self._api_key
            else:
                kwargs.update(vertexai=True, project=self._project, location=self._location)
            self._client = genai.Client(**kwargs)
        return self._client

    def _call(self, *, model: str, system: str, prompt: str, max_output_tokens: int, json_schema: dict | None) -> str:
        try:
            _, types = self._sdk()
            cfg: dict = {"system_instruction": system, "max_output_tokens": max_output_tokens, "temperature": 0.2}
            if json_schema is not None:
                cfg["response_mime_type"] = "application/json"
                cfg["response_json_schema"] = json_schema
            result = self._get_client().models.generate_content(
                model=model, contents=prompt, config=types.GenerateContentConfig(**cfg)
            )
            text = getattr(result, "text", None)
        except Exception:  # noqa: BLE001 - details may contain secrets or request data
            raise ProviderDown("The AI service did not answer.") from None
        if not text:
            raise ProviderDown("The AI service returned nothing.")
        return text

    def generate_json(self, *, system: str, prompt: str, schema: dict, max_output_tokens: int = 4000) -> str:
        return self._call(model=self.model_pro, system=system, prompt=prompt, max_output_tokens=max_output_tokens, json_schema=schema)

    def generate_text(self, *, system: str, prompt: str, max_output_tokens: int = 800) -> str:
        return self._call(model=self.model_fast, system=system, prompt=prompt, max_output_tokens=max_output_tokens, json_schema=None)
