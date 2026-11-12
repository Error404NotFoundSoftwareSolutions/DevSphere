// User story: US-11 See whether my computer is ready (Sprint 3, MVP)
// Requirements: FR-ENV-001..003, FR-ENV-009, FR-ENV-012..013
// Implemented here: view displaying readiness status of required tools

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class ReadinessPanel extends StatelessWidget {
  const ReadinessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Environment Readiness',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Row(
          children: [
            Text('Python 3.12: '),
            StatusBadge(status: StatusKind.ready),
          ],
        ),
      ],
    );
  }
}
