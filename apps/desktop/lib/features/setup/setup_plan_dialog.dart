// User story: US-12 Approve and run setup safely (Sprint 3, MVP)
// Requirements: FR-ENV-004..006, FR-ENV-011, NFR-SEC-009..010
// Implemented here: review setup plan dialog before installation

import 'package:flutter/material.dart';

class SetupPlanDialog extends StatelessWidget {
  final List<String> steps;
  final VoidCallback onApprove;

  const SetupPlanDialog(
      {super.key, required this.steps, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Setup Plan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: steps.map((s) => ListTile(title: Text(s))).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Decline')),
        ElevatedButton(
            onPressed: onApprove, child: const Text('Approve & Run')),
      ],
    );
  }
}
