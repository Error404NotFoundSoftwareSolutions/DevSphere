// User story: US-R2-5 Verify bugfix against regression test suite (Sprint 10, R2)
// Requirements: FR-BUG-004
// Implemented here: Bugfix verification view displaying regression test pass status

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class BugResult extends StatelessWidget {
  final bool passed;
  final int points;

  const BugResult({
    super.key,
    this.passed = true,
    this.points = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ResultBadge(
              kind: passed ? ResultKind.verified : ResultKind.practice,
            ),
            const SizedBox(height: 12),
            Text(
              passed ? 'Regression Test Passed!' : 'Fix Failed Regression Test',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: passed ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Points awarded: $points'),
          ],
        ),
      ),
    );
  }
}

