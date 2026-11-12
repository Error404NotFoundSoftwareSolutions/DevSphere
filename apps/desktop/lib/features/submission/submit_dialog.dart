// User story: US-28 Submit lab attempt for server grading with snapshot confirmation (Sprint 7, MVP)
// Requirements: FR-SUB-001..004
// Implemented here: Submission confirmation dialog with snapshot file summary and secret exclusion

import 'package:flutter/material.dart';

class SubmitDialog extends StatelessWidget {
  final List<String> includedFiles;
  final VoidCallback onConfirm;

  const SubmitDialog({
    super.key,
    this.includedFiles = const ['src/solution.py', 'tests/test_solution.py'],
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Lab for Verified Grading'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your workspace snapshot will be securely packaged and evaluated against the official grading test suite.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Files included in snapshot:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: includedFiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file, size: 16),
                  title: Text(includedFiles[index],
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sensitive files (.env, .git, secret keys) are strictly excluded from snapshots.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Confirm & Submit'),
        ),
      ],
    );
  }
}
