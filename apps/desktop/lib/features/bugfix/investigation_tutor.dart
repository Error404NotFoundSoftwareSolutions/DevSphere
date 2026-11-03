// User story: US-R2-4 Get investigation guidance from the debugging tutor (Sprint 10, R2)
// Requirements: FR-BUG-003
// Implemented here: Bug investigation tutor view with diagnostic hypothesis prompting

import 'package:flutter/material.dart';

class InvestigationTutor extends StatelessWidget {
  const InvestigationTutor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Investigation Tutor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Formulate a hypothesis about the root cause before writing code. '
            'Which condition in the loop fails to increment the counter?',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Ask for Investigation Strategy'),
          ),
        ],
      ),
    );
  }
}

