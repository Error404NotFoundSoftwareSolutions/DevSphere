// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// Implemented here: honest placeholder for rail sections whose stories are not built yet

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder(
      {super.key,
      required this.slug,
      required this.title,
      required this.blurb});

  final String slug;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      key: Key('page-$slug'),
      padding: const EdgeInsets.all(BL.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.headlineMedium),
          const SizedBox(height: BL.space2),
          Text(blurb, style: text.bodySmall),
          const SizedBox(height: BL.space6),
          Text('Not built yet. This section is planned and has no content.',
              style: text.bodyMedium),
          const SizedBox(height: BL.space4),
          OutlinedButton.icon(
            key: Key('placeholder_back_${slug}'),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}
