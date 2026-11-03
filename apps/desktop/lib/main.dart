// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: FR-EXEC-001..003, NFR-PERF-001..002

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'perf/startup_timer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  StartupTimer.markAppStart();
  runApp(const ProviderScope(child: DevSphereApp()));
}

