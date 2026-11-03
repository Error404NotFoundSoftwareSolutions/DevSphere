// User story: US-R3-2 Check working branch safety before push (Sprint 12, R3)
// Requirements: FR-GIT-002
// Implemented here: Branch safety checker preventing direct push to protected branches

import 'package:flutter/material.dart';

class BranchChecks extends StatelessWidget {
  final String branchName;
  final bool isProtected;

  const BranchChecks({
    super.key,
    required this.branchName,
    required this.isProtected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isProtected ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isProtected ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProtected ? Icons.gpp_bad : Icons.gpp_good,
            color: isProtected ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isProtected
                  ? 'Branch "$branchName" is protected. Please create a feature branch before pushing.'
                  : 'Branch "$branchName" is safe for contribution.',
              style: TextStyle(
                color: isProtected ? Colors.red.shade900 : Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

