// User story: US-18 Responsive interface (Sprint 4, MVP)
// Requirements: NFR-PERF-003, NFR-PERF-004
// Implemented here: non-blocking busy indicator for asynchronous actions

import 'package:flutter/material.dart';

class BusyIndicator extends StatelessWidget {
  final String? message;

  const BusyIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
