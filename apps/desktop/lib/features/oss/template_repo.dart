// User story: US-R3-3 Initialize OSS simulation from curated template repo (Sprint 13, R3)
// Requirements: FR-OSS-001
// Implemented here: Open Source template repository viewer and local clone initiator

import 'package:flutter/material.dart';

class TemplateRepo extends StatelessWidget {
  final String repoName;
  final String description;

  const TemplateRepo({
    super.key,
    this.repoName = 'community/fastapi-pagination',
    this.description =
        'Simulated upstream open-source repository with open good-first-issues.',
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
              children: [
                const Icon(Icons.source, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  repoName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Fork & Clone Upstream Simulation'),
            ),
          ],
        ),
      ),
    );
  }
}
