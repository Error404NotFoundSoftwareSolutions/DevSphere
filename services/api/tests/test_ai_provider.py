# Capability: AI gateway (docs/buildathon/PLAN.md section 4). Rules: SEC-01, SEC-10, AIR-01..AIR-09, ADR-007
# Implemented here: TC-AI-01..06 the single model provider port: fake by default, Gemini only when configured

import sys
import types

import pytest
from app.ai import provider as prov
from app.core.settings import Settings


def test_tc_ai_01_default_provider_is_the_fake_one_so_nothing_calls_out_by_accident():
    assert (
        Settings.model_fields["ai_provider"].default == "fake"
    )  # the code default, whatever .env says
    assert isinstance(prov.get_provider(), prov.FakeProvider)


def test_tc_ai_02_fake_provider_returns_scripted_answers_and_records_calls():
    f = prov.FakeProvider(json_responses=['{"a": 1}'], text_responses=["hi"])
    assert f.generate_json(system="s", prompt="p", schema={}) == '{"a": 1}'
    assert f.generate_text(system="s", prompt="p2") == "hi"
    assert [c["prompt"] for c in f.calls] == ["p", "p2"]


def test_tc_ai_03_unknown_or_unconfigured_provider_fails_closed_with_a_plain_error(monkeypatch):
    monkeypatch.setattr(prov.settings, "ai_provider", "nonsense")
    with pytest.raises(prov.AiConfigError):
        prov.build_provider()
    monkeypatch.setattr(prov.settings, "ai_provider", "gemini")
    monkeypatch.setattr(prov.settings, "gemini_project", "")
    monkeypatch.setattr(prov.settings, "gemini_api_key", "")
    with pytest.raises(prov.AiConfigError):
        prov.build_provider()


def test_tc_ai_04_gemini_adapter_passes_system_json_mode_and_limits_to_the_sdk(monkeypatch):
    seen = {}

    class Cfg:
        def __init__(self, **kw):
            seen["config"] = kw

    class Models:
        def generate_content(self, *, model, contents, config):
            seen.update(model=model, contents=contents)
            return types.SimpleNamespace(text='{"ok": true}')

    class Client:
        def __init__(self, **kw):
            seen["client"] = kw
            self.models = Models()

    fake_types = types.SimpleNamespace(GenerateContentConfig=Cfg)
    fake_genai = types.SimpleNamespace(Client=Client, types=fake_types)
    monkeypatch.setitem(sys.modules, "google.genai", fake_genai)
    monkeypatch.setitem(sys.modules, "google.genai.types", fake_types)
    from app.ai.gemini import GeminiProvider

    g = GeminiProvider(
        model_fast="m-fast", model_pro="m-pro", project="p", location="l", api_key=""
    )
    out = g.generate_json(
        system="SYS", prompt="PROMPT", schema={"type": "object"}, max_output_tokens=123
    )
    assert out == '{"ok": true}'
    assert seen["config"]["system_instruction"] == "SYS"
    assert seen["config"]["response_mime_type"] == "application/json"
    assert seen["config"]["max_output_tokens"] == 123
    assert seen["model"] == "m-pro"
    assert (
        seen["client"]["vertexai"] is True
    )  # no API key: use the service identity on Google Cloud
    assert "api_key" not in seen["client"]


def test_tc_ai_05_sdk_errors_become_provider_down_without_leaking_details(monkeypatch):
    class Models:
        def generate_content(self, **kw):
            raise RuntimeError("quota exceeded for key AIzaSySECRETSECRETSECRETSECRETSECRET12")

    class Client:
        def __init__(self, **kw):
            self.models = Models()

    fake = types.SimpleNamespace(
        Client=Client, types=types.SimpleNamespace(GenerateContentConfig=lambda **k: k)
    )
    monkeypatch.setitem(sys.modules, "google.genai", fake)
    monkeypatch.setitem(sys.modules, "google.genai.types", fake.types)
    from app.ai.gemini import GeminiProvider

    g = GeminiProvider(model_fast="a", model_pro="b", project="p", location="l", api_key="")
    with pytest.raises(prov.ProviderDown) as e:
        g.generate_text(system="s", prompt="p")
    assert "AIza" not in str(e.value)


def test_tc_ai_06_the_api_key_is_never_part_of_the_settings_text():
    s = Settings(gemini_api_key="not-a-real-key-123456")
    assert "not-a-real-key" not in repr(s)
    assert "not-a-real-key" not in str(s)


def test_tc_ai_gemini_fast_flag_picks_the_fast_model_and_pro_is_the_default():
    models: list[str] = []

    class SDK:
        def __init__(self, **kw):
            pass

        @property
        def models(self):

            class M:
                def generate_content(self, *, model, contents, config):
                    models.append(model)
                    return type("R", (), {"text": "{}"})()

            return M()

    from app.ai.gemini import GeminiProvider

    g = GeminiProvider(
        model_fast="fast-m", model_pro="pro-m", project="p", location="global", api_key=""
    )
    g._client = SDK()
    g._sdk = lambda: (None, type("T", (), {"GenerateContentConfig": staticmethod(lambda **kw: kw)}))
    g.generate_json(system="s", prompt="p", schema={})
    g.generate_json(system="s", prompt="p", schema={}, fast=True)
    assert models == ["pro-m", "fast-m"]


def test_tc_ai_gemini_retries_once_then_gives_a_plain_error(monkeypatch):
    import app.ai.gemini as gem

    monkeypatch.setattr(gem, "RETRY_DELAY_S", 0)
    state = {"calls": 0, "fail_times": 1}

    class Flaky:
        class models:  # noqa: N801
            @staticmethod
            def generate_content(**kw):
                state["calls"] += 1
                if state["calls"] <= state["fail_times"]:
                    raise RuntimeError("secret detail: key=abc")
                return type("R", (), {"text": "hello"})()

    g = gem.GeminiProvider(
        model_fast="f", model_pro="p", project="p", location="global", api_key=""
    )
    g._client = Flaky()
    g._sdk = lambda: (None, type("T", (), {"GenerateContentConfig": staticmethod(lambda **kw: kw)}))
    assert g.generate_text(system="s", prompt="p") == "hello"
    assert state["calls"] == 2

    state.update(calls=0, fail_times=5)  # keeps failing
    with pytest.raises(prov.ProviderDown) as e:
        g.generate_text(system="s", prompt="p")
    assert "secret" not in str(e.value)
    assert state["calls"] == 2, "only one retry"
