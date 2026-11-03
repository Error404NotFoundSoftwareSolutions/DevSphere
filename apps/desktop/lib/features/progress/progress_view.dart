// User story: US-21 View module progress and lab completion state (Sprint 5, MVP)
// Requirements: FR-PROG-001..003
// Implemented here: Progress view showing modules, lab completion status, and scores

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'sync_status.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Progress'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SyncStatus(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Completion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.75, minHeight: 8),
                  const SizedBox(height: 8),
                  const Text('3 of 4 Labs Completed (75%)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Labs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Lab 01: Python Basics & Clean Code'),
              subtitle: const Text('Score: 100/100'),
              trailing: const ResultBadge(kind: ResultKind.verified),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Lab 02: REST APIs with FastAPI'),
              subtitle: const Text('Score: 95/100'),
              trailing: const ResultBadge(kind: ResultKind.verified),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: const Text('Lab 03: Database Persistence with SQLite'),
              subtitle: const Text('In progress'),
              trailing: const ResultBadge(kind: ResultKind.practice),
            ),
          ),
        ],
      ),
    );
  }
}

