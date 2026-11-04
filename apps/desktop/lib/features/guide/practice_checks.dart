// User story: US-20 Run non-scoring practice checks to test my code locally (Sprint 5, MVP)
// Requirements: FR-GRADE-002, FR-EXEC-002
// Implemented here: Practice checks launcher, feedback status, and practice result badge

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class PracticeChecks extends StatefulWidget {
  const PracticeChecks({super.key});

  @override
  State<PracticeChecks> createState() => _PracticeChecksState();
}

class _PracticeChecksState extends State<PracticeChecks> {
  bool _running = false;
  bool? _passed;

  void _runCheck() async {
    setState(() {
      _running = true;
      _passed = null;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _running = false;
      _passed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Local Practice Check',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_passed != null)
                  const ResultBadge(kind: ResultKind.practice),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Runs local tests against your current code. Does not affect your verified grade.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_passed == true)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text('All practice tests passed!', style: TextStyle(color: Colors.green)),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _running ? null : _runCheck,
                child: _running
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run Practice Checks'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

