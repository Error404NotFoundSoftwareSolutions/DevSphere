// User story: US-R3-4 Track simulated PR reviews and automated bot checks (Sprint 13, R3)
// Requirements: FR-OSS-002
// Implemented here: Pull request simulation tracker showing status, automated bot reviews, and CI checks

import 'package:flutter/material.dart';

class PullRequestTracker extends StatelessWidget {
  final int prNumber;
  final String title;
  final String status;
  final List<String> reviewComments;

  const PullRequestTracker({
    super.key,
    this.prNumber = 42,
    this.title = 'Add cursor-based pagination helper',
    this.status = 'Changes Requested',
    this.reviewComments = const [
      'bot-reviewer: Unit tests pass. Linting found missing type annotations on line 45.',
      'maintainer-sim: Nice work! Can you add a test covering null cursors?',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PR #$prNumber: $title',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const Divider(height: 20),
            Text('Review Feedback:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...reviewComments.map((comment) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(comment, style: const TextStyle(fontSize: 12)),
                )),
          ],
        ),
      ),
    );
  }
}

