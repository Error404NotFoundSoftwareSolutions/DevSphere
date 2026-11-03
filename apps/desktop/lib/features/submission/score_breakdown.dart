// User story: US-34 Inspect rubric item scores and automated feedback (Sprint 8, MVP)
// Requirements: FR-GRADE-006
// Implemented here: Rubric score breakdown widget with points awarded per evaluation criterion

import 'package:flutter/material.dart';

class ScoreBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const ScoreBreakdown({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rubric Breakdown',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final label = item['label'] as String;
              final score = item['score'] as int;
              final max = item['max'] as int;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label),
                    Text(
                      '$score / $max pts',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

