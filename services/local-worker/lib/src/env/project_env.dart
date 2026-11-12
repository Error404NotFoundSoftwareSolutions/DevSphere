// User story: US-13 Create the project environment and recover from failure (Sprint 3, MVP)
// Requirements: FR-ENV-007, FR-ENV-008, FR-ENV-010
// Implemented here: isolated project environment creation via uv sync --frozen

import '../exec/safe_spawn.dart';

Future<RunResult> createProjectEnvironment(String workspaceDir) async {
  return runProcess(
    'uv',
    ['sync', '--frozen'],
    cwd: workspaceDir,
    timeout: const Duration(seconds: 120),
  );
}
