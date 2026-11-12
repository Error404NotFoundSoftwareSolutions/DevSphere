// User story: US-22 Work offline and have local progress buffered until reconnect (Sprint 5, MVP)
// Requirements: FR-PROG-004, FR-PROG-005
// Implemented here: Sync indicator showing online/offline status and buffered outbox items

import 'package:flutter/material.dart';

class SyncStatus extends StatelessWidget {
  final bool isOnline;
  final int pendingOutboxCount;

  const SyncStatus({
    super.key,
    this.isOnline = true,
    this.pendingOutboxCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return Chip(
        avatar: const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
        label: Text('Offline ($pendingOutboxCount queued)'),
        backgroundColor: Colors.orange.shade50,
      );
    }

    if (pendingOutboxCount > 0) {
      return Chip(
        avatar: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('Syncing ($pendingOutboxCount)'),
      );
    }

    return const Chip(
      avatar: Icon(Icons.cloud_done, size: 16, color: Colors.green),
      label: Text('Synced'),
    );
  }
}
