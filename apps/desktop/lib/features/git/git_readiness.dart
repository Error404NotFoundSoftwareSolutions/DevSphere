// User story: US-R3-1 Validate local Git configuration and signing keys (Sprint 12, R3)
// Requirements: FR-GIT-001
// Implemented here: Git readiness panel checking git identity, config, and commit signing

import 'package:flutter/material.dart';

class GitReadiness extends StatelessWidget {
  final bool hasGit;
  final bool hasIdentity;
  final bool hasSigningKey;

  const GitReadiness({
    super.key,
    this.hasGit = true,
    this.hasIdentity = true,
    this.hasSigningKey = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Git Configuration & Readiness',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRow('Git CLI Installed', hasGit),
            _buildRow('User Identity (name, email) Configured', hasIdentity),
            _buildRow('Commit Signing Key (GPG/SSH)', hasSigningKey),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber,
            color: ok ? Colors.green : Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

