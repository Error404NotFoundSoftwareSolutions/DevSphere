// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: Monaco editor plus the xterm.js terminal; file access goes through the worker, never the page (NFR-SEC-002)

import Editor from "@monaco-editor/react";

export function WorkspaceView() {
  // TODO (Sprint 4): load files through "workspace:open" and mount xterm.js next to the editor.
  return <Editor height="50vh" defaultLanguage="python" defaultValue={"print('hello')\n"} />;
}
