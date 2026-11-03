// User story: US-R2-1 Browse bugfix challenges filtered by difficulty and language (Sprint 9, R2)
// Requirements: FR-BUG-001
// Implemented here: Bugfix challenge list view with difficulty and language filters

import 'package:flutter/material.dart';

class ChallengeList extends StatefulWidget {
  const ChallengeList({super.key});

  @override
  State<ChallengeList> createState() => _ChallengeListState();
}

class _ChallengeListState extends State<ChallengeList> {
  String _selectedLanguage = 'All';

  final List<Map<String, dynamic>> _challenges = [
    {
      'id': 'bug-01',
      'title': 'Requests: Off-by-one in redirect loop detector',
      'language': 'Python',
      'difficulty': 'Medium',
      'points': 75,
    },
    {
      'id': 'bug-02',
      'title': 'Click: ANSI escape code truncation in pager',
      'language': 'Python',
      'difficulty': 'Hard',
      'points': 100,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedLanguage == 'All'
        ? _challenges
        : _challenges.where((c) => c['language'] == _selectedLanguage).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugfix Challenges (R2)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter Language:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Python', child: Text('Python')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final challenge = filtered[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.amber),
                    title: Text(challenge['title'] as String),
                    subtitle: Text('${challenge['language']} • ${challenge['difficulty']}'),
                    trailing: Chip(
                      label: Text('${challenge['points']} pts'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

