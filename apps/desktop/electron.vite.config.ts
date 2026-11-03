// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: build config: main, preload and the local worker are separate bundles; native modules stay external (NFR-PORT-005)

import { defineConfig, externalizeDepsPlugin } from "electron-vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

const shared = ["@devsphere/ipc-contract", "@devsphere/redaction"]; // bundled, not external

export default defineConfig({
  main: {
    plugins: [externalizeDepsPlugin({ exclude: shared })],
    build: {
      rollupOptions: {
        input: { index: "src/main/index.ts", worker: "../../services/local-worker/src/index.ts" },
      },
    },
  },
  preload: { plugins: [externalizeDepsPlugin({ exclude: shared })] },
  renderer: { plugins: [react(), tailwindcss()] },
});
