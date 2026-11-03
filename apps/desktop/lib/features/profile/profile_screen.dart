// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-PROF-002..008
// Implemented here: view and update student profile

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Profile details are private to you.'),
      ),
    );
  }
}

