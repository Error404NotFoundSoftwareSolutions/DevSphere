// User story: US-23 Ask the tutor with context I control (Sprint 6, MVP)
// Requirements: FR-AI-001, FR-AI-004, FR-AI-012, FR-AI-014, NFR-PRIV-001..002
// User story: US-24 Get hints that teach, not only answers (Sprint 6, MVP)
// Requirements: FR-AI-006..008, FR-AI-016
// User story: US-27 Keep working when AI is down (Sprint 6, MVP)
// Requirements: FR-AI-010..011
// Implemented here: ask the tutor; show what is shared; pick a hint level; show a clear message when AI is down

import { useState } from "react";
import { call } from "../../api";

export function TutorPanel() {
  const [question, setQuestion] = useState("");
  const [level, setLevel] = useState(2); // US-24: progressive help, capped by the lab on the server
  const [shareCode, setShareCode] = useState(false); // US-23: default is minimal context
  const [error, setError] = useState<string | null>(null);

  async function ask() {
    try {
      await call("tutor:ask", { attemptId: "a1", question, level, shareCode });
    } catch {
      setError("The tutor is not available right now. You can keep working; try again later.");
    } // US-27
  }
  return (
    <section aria-labelledby="tutor-title">
      <h2 id="tutor-title">Tutor</h2>
      <label>
        Question <input value={question} onChange={(e) => setQuestion(e.target.value)} />
      </label>
      <label>
        <input
          type="checkbox"
          checked={shareCode}
          onChange={(e) => setShareCode(e.target.checked)}
        />{" "}
        Share my selected code (it is sent to a cloud AI provider)
      </label>
      <label>
        Help level{" "}
        <input
          type="range"
          min={1}
          max={6}
          value={level}
          onChange={(e) => setLevel(Number(e.target.value))}
        />
      </label>
      <button onClick={ask}>Ask</button>
      {error && <p role="alert">{error}</p>}
    </section>
  );
}
