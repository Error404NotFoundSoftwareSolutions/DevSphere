// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// User story: US-09 Author a lab as files with CI checks (Sprint 2, MVP)
// Requirements: FR-CONT-001..005, NFR-MAINT-002, NFR-LEGAL-002
// Implemented here: manifest validation: the app uses it before opening a lab (FR-CAT-002/003); labcheck mirrors it in Python

import Ajv2020 from "ajv/dist/2020";
import schema from "../manifest.schema.json";

const ajv = new Ajv2020({ allErrors: true, strict: false });
const validateSchema = ajv.compile(schema);

export type ValidationResult = { ok: true } | { ok: false; errors: string[] };

export function validateManifest(manifest: unknown): ValidationResult {
  // Unsupported versions get a clear message instead of a silent failure (FR-CAT-003).
  const v = (manifest as { schema_version?: unknown } | null)?.schema_version;
  if (v !== 1) {
    return {
      ok: false,
      errors: [
        `This lab needs a newer app version (schema_version ${String(v)}). Please update the app.`,
      ],
    };
  }
  if (validateSchema(manifest)) return { ok: true };
  return {
    ok: false,
    errors: (validateSchema.errors ?? []).map((e) => `${e.instancePath} ${e.message}`),
  };
}

// Rubric weights must add up to max_points (FR-CONT-002).
export function checkPointsTotal(m: {
  evaluation: { max_points: number; checks: { points: number }[] };
}): boolean {
  return m.evaluation.checks.reduce((sum, c) => sum + c.points, 0) === m.evaluation.max_points;
}
