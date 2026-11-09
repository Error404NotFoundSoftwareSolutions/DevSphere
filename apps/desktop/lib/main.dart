// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: FR-EXEC-001..003, NFR-PERF-001..002
// Implemented here: app entry point. Wires the real worker client (ADR-022). If the worker program is
// missing the app uses a client that says so plainly instead of pretending to work.

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'app.dart';
import 'data/file_user_store.dart';
import 'firebase_options.dart';
import 'perf/startup_timer.dart';
import 'worker/process_worker_client.dart';
import 'worker/worker_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimer.markAppStart();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  final paths = realAppPaths();
  final WorkerClient client = paths.worker == null
      ? UnavailableWorkerClient(
          'DevPilot could not find its helper program, so it cannot open labs in VS Code.')
      : ProcessWorkerClient(executable: paths.worker!, args: workerArgs(paths));
  runApp(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(client),
      userStoreProvider.overrideWithValue(FileUserStore.defaultLocation(Platform.environment)),
    ],
    child: DevPilotApp(),
  ));
}
