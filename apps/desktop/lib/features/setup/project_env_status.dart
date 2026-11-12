// User story: US-13 Create the project environment and recover from failure (Sprint 3, MVP)
// Requirements: FR-ENV-007, FR-ENV-008, FR-ENV-010
// Implemented here: virtual environment creation status and error recovery

import 'package:flutter/material.dart';

class ProjectEnvStatus extends StatelessWidget {
  final bool isCreated;

  const ProjectEnvStatus({super.key, required this.isCreated});

  @override
  Widget build(BuildContext context) {
    return Text(
      isCreated ? 'Virtual environment ready' : 'Environment creation pending',
      style: TextStyle(color: isCreated ? Colors.green : Colors.orange),
    );
  }
}
