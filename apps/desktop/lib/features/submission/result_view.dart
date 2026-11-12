// User story: US-30 View verified grading result and test execution details (Sprint 7, MVP)
// Requirements: FR-GRADE-001..005
// Implemented here: Verified result screen showing overall score, badges, and test case status

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'score_breakdown.dart';

class ResultView extends StatelessWidget {
  final int score;
  final int maxScore;
  final bool isVerified;
  final List<Map<String, dynamic>> testCases;

  const ResultView({
    super.key,
    this.score = 100,
    this.maxScore = 100,
    this.isVerified = true,
    this.testCases = const [
      {'name': 'test_basic_greeting', 'passed': true, 'points': 50},
      {'name': 'test_whitespace_stripping', 'passed': true, 'points': 50},
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Results'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ResultBadge(
                    kind:
                        isVerified ? ResultKind.verified : ResultKind.practice,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$score / $maxScore',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: score == maxScore ? Colors.green : Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified
                        ? 'Official grading completed by sandboxed server runner.'
                        : 'Practice check executed locally.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Test Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...testCases.map((tc) => Card(
                child: ListTile(
                  leading: Icon(
                    tc['passed'] == true ? Icons.check_circle : Icons.cancel,
                    color: tc['passed'] == true ? Colors.green : Colors.red,
                  ),
                  title: Text(tc['name'] as String),
                  trailing: Text('+${tc['points']} pts'),
                ),
              )),
          const SizedBox(height: 20),
          ScoreBreakdown(
            items: [
              {'label': 'Functional Correctness', 'score': 50, 'max': 50},
              {'label': 'Edge Case Handling', 'score': 50, 'max': 50},
            ],
          ),
        ],
      ),
    );
  }
}
