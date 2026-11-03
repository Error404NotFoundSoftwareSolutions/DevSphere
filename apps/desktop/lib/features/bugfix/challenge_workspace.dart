// User story: US-R2-3 Work on a real-world repository bug reproduction (Sprint 9, R2)
// Requirements: FR-BUG-002
// Implemented here: Bug reproduction workspace view with reproduction command triggers

import 'package:flutter/material.dart';

class ChallengeWorkspace extends StatelessWidget {
  final String challengeId;

  const ChallengeWorkspace({
    super.key,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bugfix Workspace: $challengeId'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Reproduce Bug'),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '// Inspecting reproduction test case\ndef test_redirect_loop_boundary():\n    # Reproduction trigger\n    ...',
                style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bug Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Issue description and failing stack traces go here.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

