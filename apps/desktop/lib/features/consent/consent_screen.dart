// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// Requirements: FR-PROF-001, FR-PROF-010
// Implemented here: privacy disclosure and student consent dialog

import 'package:flutter/material.dart';

class ConsentScreen extends StatelessWidget {
  final VoidCallback onConsent;

  const ConsentScreen({super.key, required this.onConsent});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Notice & Consent'),
      content: const Text(
        'DevSphere stores only minimal progress and evaluation records. '
        'You confirm that you are at least 18 years old and consent to data processing.',
      ),
      actions: [
        TextButton(
          onPressed: onConsent,
          child: const Text('I Agree'),
        ),
      ],
    );
  }
}

