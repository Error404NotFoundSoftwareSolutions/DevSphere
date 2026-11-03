// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003

library local_worker;

export 'src/exec/safe_spawn.dart';
export 'src/exec/run_task.dart';
export 'src/exec/approvals.dart';
export 'src/env/detect.dart';
export 'src/env/setup_plan.dart';
export 'src/env/project_env.dart';
export 'src/bundles/verify_bundle.dart';
export 'src/workspace/open_workspace.dart';
export 'src/checks/practice.dart';
export 'src/progress/recorder.dart';
export 'src/store/db.dart';
export 'src/store/outbox.dart';
export 'src/sync/sync_client.dart';
export 'src/snapshot/build_snapshot.dart';
export 'src/attempts/pinning.dart';
export 'src/platform/platform_adapter.dart';
export 'src/terminal/pty_service.dart';
export 'src/git/git_readiness.dart';
export 'src/git/branch_checks.dart';
export 'src/bug/reset_workspace.dart';
export 'src/handlers.dart';

