// User story: US-04 Request data export or deletion (Sprint 1, MVP)
// Requirements: FR-PROF-009, NFR-SEC-013
// Implemented here: request student data export or account deletion

import 'package:flutter/material.dart';

class DataRequestsView extends StatelessWidget {
  const DataRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Export My Data'),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Delete My Account'),
        ),
      ],
    );
  }
}

