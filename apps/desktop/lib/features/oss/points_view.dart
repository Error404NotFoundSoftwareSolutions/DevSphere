// User story: US-R3-6 View OSS contribution points and badges (Sprint 14, R3)
// Requirements: FR-OSS-003
// Implemented here: OSS contribution points dashboard and milestone badges view

import 'package:flutter/material.dart';

class PointsView extends StatelessWidget {
  final int ossPoints;
  final List<String> badges;

  const PointsView({
    super.key,
    this.ossPoints = 250,
    this.badges = const [
      'First PR Merged',
      'Clean CI Runner',
      'Review Feedback Addressed',
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
                  'OSS Contribution Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$ossPoints pts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Earned Badges', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges
                  .map((b) => Chip(
                        avatar: const Icon(Icons.stars, color: Colors.amber, size: 18),
                        label: Text(b),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

