# Capability: Tutor with a language setting. Rules: AIR-01, TRU-03, FR-AI-006..008
# Implemented here: TC-AI-40..43 language is a validated parameter; the level cap still wins; the model sees redacted text
from app.ai import provider as prov
from app.tutor.policy import LANGUAGES, build_prompt
from conftest import STUDENT


def attempt(client):
    return client.post("/v1/attempts", json={"lab_id": "python-hello-001"}, headers=STUDENT).json()


def test_tc_ai_40_the_prompt_asks_for_the_chosen_language_and_keeps_code_in_english():
    p = build_prompt(2, "what is a loop", None, language="kn")
    assert "Kannada" in p and "code" in p.lower()
    assert "English" in build_prompt(2, "q", None)


def test_tc_ai_41_only_supported_languages_are_accepted(client):
    a = attempt(client)
    assert set(LANGUAGES) >= {"en", "hi", "kn", "ta", "te"}
    r = client.post("/v1/tutor/messages", json={"attempt_id": a["id"], "question": "help", "level": 2, "language": "klingon"}, headers=STUDENT)
    assert r.status_code == 422


def test_tc_ai_42_the_model_gets_redacted_text_and_the_lab_cap_still_wins(client):
    f = prov.FakeProvider(text_responses=["Soch kar dekho."])
    prov.set_provider(f)
    a = attempt(client)
    r = client.post("/v1/tutor/messages", json={"attempt_id": a["id"], "question": "my password = hunter2hunter2", "level": 6, "language": "hi"}, headers=STUDENT)
    assert r.status_code == 200 and r.json()["level"] == 4 and r.json()["answer"] == "Soch kar dekho."
    assert "hunter2hunter2" not in f.calls[0]["prompt"]
    assert "Hindi" in f.calls[0]["prompt"]


def test_tc_ai_43_when_the_model_is_down_the_learner_gets_the_plain_unavailable_message(client):
    class Down(prov.FakeProvider):
        def generate_text(self, **kw):
            raise prov.ProviderDown("x")
    prov.set_provider(Down())
    a = attempt(client)
    r = client.post("/v1/tutor/messages", json={"attempt_id": a["id"], "question": "help", "level": 2}, headers=STUDENT)
    assert r.status_code == 503 and r.json()["code"] == "ai_unavailable"
