// User story: US-03 Create and manage my profile (Sprint 1, MVP)
// Requirements: FR-PROF-002..008
// Implemented here: view and update student profile with prefilled editable display name, optional college/academic fields, and privacy notice

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../firestore/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? initialDisplayName;
  final String? initialCollege;
  final String? initialCourse;
  final String? initialAcademicYear;
  final List<String>? initialInterests;
  final bool isOnboarding;
  final void Function(StudentProfile profile)? onSave;
  final FirestoreService? firestoreService;

  const ProfileScreen({
    super.key,
    this.uid,
    this.email,
    this.initialDisplayName,
    this.initialCollege,
    this.initialCourse,
    this.initialAcademicYear,
    this.initialInterests,
    this.isOnboarding = false,
    this.onSave,
    this.firestoreService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _collegeController;
  late final TextEditingController _courseController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _interestsController;

  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialDisplayName ?? '');
    _collegeController = TextEditingController(text: widget.initialCollege ?? '');
    _courseController = TextEditingController(text: widget.initialCourse ?? '');
    _academicYearController = TextEditingController(text: widget.initialAcademicYear ?? '');
    _interestsController = TextEditingController(
      text: widget.initialInterests != null ? widget.initialInterests!.join(', ') : '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _academicYearController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final interests = _interestsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final profile = StudentProfile(
      uid: widget.uid ?? 'default-user',
      displayName: _displayNameController.text.trim(),
      email: widget.email ?? '',
      college: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
      course: _courseController.text.trim().isEmpty ? null : _courseController.text.trim(),
      academicYear: _academicYearController.text.trim().isEmpty ? null : _academicYearController.text.trim(),
      interests: interests,
    );

    try {
      if (widget.firestoreService != null) {
        await widget.firestoreService!.saveProfile(profile);
      }
      widget.onSave?.call(profile);
      if (mounted) {
        setState(() {
          _statusMessage = 'Profile saved successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to save profile. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('profile_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(widget.isOnboarding ? '/' : '/dashboard');
            }
          },
        ),
        title: Text(widget.isOnboarding ? 'Set Up Your Profile' : 'My Profile'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Privacy disclosure banner (FR-PROF-007)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profile data is private by default and visible only to you.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display Name field (FR-PROF-002: required, editable, prefilled)
                  TextFormField(
                    key: const Key('profile_display_name_field'),
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name *',
                      helperText: 'Prefilled from your sign-in account. Editable anytime.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Display name is required.';
                      }
                      if (value.trim().length > 60) {
                        return 'Display name must not exceed 60 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // College field (FR-PROF-003: optional)
                  TextFormField(
                    key: const Key('profile_college_field'),
                    controller: _collegeController,
                    decoration: const InputDecoration(
                      labelText: 'College / University (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Course field (FR-PROF-003: optional)
                  TextFormField(
                    key: const Key('profile_course_field'),
                    controller: _courseController,
                    decoration: const InputDecoration(
                      labelText: 'Course / Degree (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Academic Year/Semester field (FR-PROF-003: optional)
                  TextFormField(
                    key: const Key('profile_academic_year_field'),
                    controller: _academicYearController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year / Semester (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interests field (FR-PROF-003: optional)
                  TextFormField(
                    key: const Key('profile_interests_field'),
                    controller: _interestsController,
                    decoration: const InputDecoration(
                      labelText: 'Interests (comma-separated, optional)',
                      hintText: 'e.g. Python, Machine Learning, Web Development',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_statusMessage != null) ...[
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage!.contains('Failed') ? theme.colorScheme.error : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('profile_cancel_back_button'),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go(widget.isOnboarding ? '/' : '/dashboard');
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          key: const Key('profile_save_button'),
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.isOnboarding ? 'Save & Continue' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
