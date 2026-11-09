// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: root DevPilot MaterialApp widget (DevPilot theme from packages/ui)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'router.dart';

class DevPilotApp extends StatelessWidget {
  DevPilotApp({super.key, GoRouter? router}) : router = router ?? appRouter;

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DevPilot',
      debugShowCheckedModeBanner: false,
      theme: devPilotTheme(),
      routerConfig: router,
    );
  }
}
