// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-PROF-002..008, FR-PROF-010
// Implemented here: the /profile page for the person who is signed in. It shows and saves THEIR profile only, kept
// in their own private data. Nothing about another person can appear here. Email is shown but never stored here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../auth/auth_session.dart';
import '../pages/shared.dart';
import 'profile_screen.dart';

class MyProfileRoute extends ConsumerWidget {
  const MyProfileRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(userDataProvider);
    final user = AuthSession.instance.user;
    final data = controller.data;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: const Padding(
              padding: EdgeInsets.all(32), child: SignedOutNotice()));
    }
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = data.profile;
    final neverSaved = p.college.isEmpty &&
        p.course.isEmpty &&
        p.academicYear.isEmpty &&
        p.interests.isEmpty;
    return ProfileScreen(
      key: ValueKey('profile-${user.uid}'),
      uid: user.uid,
      email: user.email,
      initialDisplayName: p.displayName.isEmpty ? user.label : p.displayName,
      initialCollege: p.college,
      initialCourse: p.course,
      initialAcademicYear: p.academicYear,
      initialInterests: p.interests,
      isOnboarding: neverSaved,
      onSave: (saved) {
        ref.read(userDataProvider).saveProfile(UserProfile(
              displayName: saved.displayName,
              college: saved.college ?? '',
              course: saved.course ?? '',
              academicYear: saved.academicYear ?? '',
              interests: saved.interests,
            ));
        context.go('/dashboard');
      },
    );
  }
}
