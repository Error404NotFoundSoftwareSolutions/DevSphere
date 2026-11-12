// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: FR-EXEC-001..003, NFR-PERF-001..002
// Implemented here: app entry point. Wires the real worker client (ADR-022). If the worker program is
// missing the app uses a client that says so plainly instead of pretending to work.

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'features/learn/video_player.dart' show playerLauncherProvider;
import 'services/player_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'app.dart';
import 'data/app_prefs.dart';
import 'data/file_user_store.dart';
import 'features/auth/session_store.dart';
import 'services/devpilot_api.dart';
import 'services/service_health.dart';
import 'firebase_options.dart';
import 'perf/startup_timer.dart';
import 'worker/process_worker_client.dart';
import 'worker/worker_locator.dart';

/// The service address when DEVPILOT_API_URL is not set. Release builds are made with
/// --dart-define=DEVPILOT_DEFAULT_API_URL=<the hosted service>; development uses the local one.
const defaultApiUrl = String.fromEnvironment('DEVPILOT_DEFAULT_API_URL',
    defaultValue: 'http://127.0.0.1:8787');

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
  final prefs = AppPrefs.defaultLocation(Platform.environment);
  final startDark = prefs.loadDark();
  final paths = realAppPaths();
  final WorkerClient client = paths.worker == null
      ? UnavailableWorkerClient(
          'DevPilot could not find its helper program, so it cannot open labs in VS Code.')
      : ProcessWorkerClient(executable: paths.worker!, args: workerArgs(paths));
  runApp(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(client),
      themeDarkProvider.overrideWith(
          (ref) => ThemeModeController(startDark, prefs.saveDark)),
      userStoreProvider.overrideWithValue(
          FileUserStore.defaultLocation(Platform.environment)),
      serviceHealthCheckProvider.overrideWithValue(() => checkService(
          Platform.environment['DEVPILOT_API_URL'] ?? defaultApiUrl)),
      playerLauncherProvider.overrideWithValue(openPlayerWindow),
      devPilotApiProvider.overrideWithValue(HttpDevPilotApi(
        baseUrl: Platform.environment['DEVPILOT_API_URL'] ?? defaultApiUrl,
        token: () => SessionStore.app.readToken(),
      )),
    ],
    child: DevPilotApp(),
  ));
}
