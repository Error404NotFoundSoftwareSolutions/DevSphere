// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: root DevPilot MaterialApp widget (DevPilot theme from packages/ui)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'data/app_prefs.dart';
import 'router.dart';

class DevPilotApp extends ConsumerWidget {
  DevPilotApp({super.key, GoRouter? router}) : router = router ?? appRouter;

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeDarkProvider);
    BL.dark = dark; // the colour tokens follow the switch
    return MaterialApp.router(
      // A new key rebuilds every screen so each one re-reads the colours. The router keeps the current page.
      key: ValueKey(dark ? 'dark' : 'light'),
      title: 'DevPilot',
      debugShowCheckedModeBanner: false,
      theme: devPilotTheme(),
      routerConfig: router,
    );
  }
}
