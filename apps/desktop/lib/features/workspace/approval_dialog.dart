// User story: US-17 Stay in control of what runs (Sprint 4, MVP)
// Requirements: FR-EXEC-004, FR-EXEC-007, FR-EXEC-008
// Implemented here: Approval dialog for privileged commands and AI-suggested actions

import 'package:flutter/material.dart';

class ApprovalDialog extends StatelessWidget {
  final String actionDescription;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const ApprovalDialog({
    super.key,
    required this.actionDescription,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Action'),
      content:
          Text('DevSphere requests permission to run:\n\n$actionDescription'),
      actions: [
        TextButton(onPressed: onDecline, child: const Text('Decline')),
        ElevatedButton(onPressed: onApprove, child: const Text('Allow Once')),
      ],
    );
  }
}
