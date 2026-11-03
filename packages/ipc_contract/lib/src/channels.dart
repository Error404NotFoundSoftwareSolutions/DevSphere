// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: the list of every call the UI may make. Add new channels here AND in docs/IPC_API.md

const List<String> channels = [
  "auth:signIn",
  "auth:signOut",
  "auth:getSession",
  "catalogue:list",
  "bundle:download",
  "env:detect",
  "env:plan",
  "env:apply",
  "workspace:open",
  "task:run",
  "task:stop",
  "approval:respond",
  "progress:record",
  "sync:status",
  "tutor:ask",
  "tutor:cancel",
  "submission:preview",
  "submission:submit",
];

const List<String> events = [
  "task:output",
  "sync:changed",
  "terminal:data",
];

bool isChannel(String name) => channels.contains(name);

