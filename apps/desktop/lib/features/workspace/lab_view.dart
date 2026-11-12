// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: container widget managing lab attempt state

import 'package:flutter/material.dart';
import 'workspace_view.dart';

class LabView extends StatelessWidget {
  final String attemptId;

  const LabView({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    return WorkspaceView(attemptId: attemptId);
  }
}
