// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-UX-001..007
// Implemented here: Status badge for tool readiness, task execution, etc.

import 'package:flutter/material.dart';
import 'labels.dart';

class StatusBadge extends StatelessWidget {
  final StatusKind status;

  const StatusBadge({super.key, required this.status});

  Color _statusColor(StatusKind s) {
    switch (s) {
      case StatusKind.ready:
      case StatusKind.passed:
        return Colors.green;
      case StatusKind.missing:
      case StatusKind.failed:
        return Colors.red;
      case StatusKind.installing:
      case StatusKind.verifying:
        return Colors.blue;
      case StatusKind.blocked:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

