// User story: US-31 Practice results are labelled (Sprint 7, MVP)
// Requirements: FR-GRADE-002
// Implemented here: Result badge displaying Practice (unverified) vs Verified

import 'package:flutter/material.dart';
import 'labels.dart';

class ResultBadge extends StatelessWidget {
  final ResultKind kind;

  const ResultBadge({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final isVerified = kind == ResultKind.verified;
    final color = isVerified ? Colors.green : Colors.amber;
    final text = resultLabel(kind);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

