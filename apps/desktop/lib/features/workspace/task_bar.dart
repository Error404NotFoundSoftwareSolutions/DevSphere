// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, FR-EXEC-005..006, FR-EXEC-009, NFR-SEC-002..003
// Implemented here: Task bar for running practice checks and stopping tasks

import 'package:flutter/material.dart';

class TaskBar extends StatelessWidget {
  const TaskBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Run Practice Checks',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          tooltip: 'Stop Task',
          onPressed: () {},
        ),
      ],
    );
  }
}
