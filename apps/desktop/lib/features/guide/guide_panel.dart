// User story: US-19 Read lab instructions with a fixed table of contents and step progress (Sprint 5, MVP)
// Requirements: FR-GUIDE-001..003
// Implemented here: Guide panel with table of contents, step instruction, and practice check trigger

import 'package:flutter/material.dart';
import 'practice_checks.dart';

class GuidePanel extends StatefulWidget {
  const GuidePanel({super.key});

  @override
  State<GuidePanel> createState() => _GuidePanelState();
}

class _GuidePanelState extends State<GuidePanel> {
  int currentStep = 1;
  final int totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lab Instructions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Text(
            'Step $currentStep of $totalSteps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              children: [
                Text(
                  'Task: Implement greeting function',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Write a function `greet(name)` that returns `Hello, <name>!`. '
                  'Ensure that leading and trailing whitespaces in names are handled cleanly.',
                ),
                const SizedBox(height: 16),
                const PracticeChecks(),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: currentStep > 1
                    ? () => setState(() => currentStep--)
                    : null,
                child: const Text('Previous'),
              ),
              FilledButton(
                onPressed: currentStep < totalSteps
                    ? () => setState(() => currentStep++)
                    : null,
                child: const Text('Next Step'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

