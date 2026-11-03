// User story: US-08 Keep my attempt on one lab version (Sprint 2, MVP)
// Requirements: FR-CAT-005, FR-CAT-006
// Implemented here: notification banner when newer lab version is published

import 'package:flutter/material.dart';

class NewVersionBanner extends StatelessWidget {
  final String newerVersion;

  const NewVersionBanner({super.key, required this.newerVersion});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text('A newer version ($newerVersion) of this lab is available.'),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text('View Changelog'),
        ),
      ],
    );
  }
}

