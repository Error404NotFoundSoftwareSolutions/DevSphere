// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003
// Implemented here: lab catalogue list view

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DevSphere Labs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Hello, Python'),
              subtitle: const Text('Write and test your first function • Beginner • 45 min'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                context.go('/workspace/attempt-hello-001');
              },
            ),
          ),
        ],
      ),
    );
  }
}

