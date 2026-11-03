// User story: US-28 Submit my work for verification (Sprint 7, MVP)
// Requirements: FR-GRADE-003..004, NFR-SEC-014
// Implemented here: show exactly which files will be uploaded, then ask for confirmation (FR-GRADE-004)

import { useState } from "react";
import { call } from "../../api";

export function SubmitDialog({ attemptId }: { attemptId: string }) {
  const [files, setFiles] = useState<string[]>([]);
  const [excluded, setExcluded] = useState<string[]>([]);
  async function preview() {
    const r = await call<{ files: string[]; excluded: string[] }>("submission:preview", {
      attemptId,
    });
    setFiles(r.files);
    setExcluded(r.excluded);
  }
  return (
    <section aria-labelledby="submit-title">
      <h2 id="submit-title">Submit for verification</h2>
      <button onClick={preview}>Show files</button>
      <p>
        {files.length} files will be sent. {excluded.length} were left out (for example .env files).
      </p>
      <button
        disabled={files.length === 0}
        onClick={() => call("submission:submit", { attemptId, confirmedFiles: files })}
      >
        Confirm and submit
      </button>
    </section>
  );
}
