// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: FR-EXEC-001..003, NFR-PERF-001..002

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'perf/startup_timer.dart';

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
  runApp(const ProviderScope(child: DevSphereApp()));
}
