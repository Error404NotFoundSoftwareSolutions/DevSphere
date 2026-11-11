// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: app-wide IPC and API client provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/user_controller.dart';
import 'data/user_store.dart';
import 'services/devpilot_api.dart';
import 'worker/worker_client.dart';

final workerClientProvider = Provider<WorkerClient>((ref) {
  return MockWorkerClient();
});


/// Where each person's profile and progress are kept. `main.dart` replaces this with a private folder on disk;
/// the default keeps data in memory only, which is what widget tests want.
final userStoreProvider = Provider<UserStore>((ref) => MemoryUserStore());

/// The signed-in person's own data. It is empty when nobody is signed in and switches when someone else signs in.
final userDataProvider = ChangeNotifierProvider<UserDataController>((ref) {
  return UserDataController(ref.watch(userStoreProvider));
});

/// The DevPilot API (roadmap planner, tutor). `main.dart` wires the real one; the default says it is offline.
final devPilotApiProvider = Provider<DevPilotApi>((ref) => const OfflineDevPilotApi());
