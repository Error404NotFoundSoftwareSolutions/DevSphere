// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: app-wide IPC and API client provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worker/worker_client.dart';

final workerClientProvider = Provider<WorkerClient>((ref) {
  return MockWorkerClient();
});

