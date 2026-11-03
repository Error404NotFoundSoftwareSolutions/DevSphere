import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default [
  { ignores: ["**/dist/**", "**/out/**", "**/node_modules/**", "**/.venv/**", "docs/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      // Safety rules from .agent/RULES.md: no shell strings, no eval.
      "no-eval": "error",
      "no-implied-eval": "error",
    },
  },
];
