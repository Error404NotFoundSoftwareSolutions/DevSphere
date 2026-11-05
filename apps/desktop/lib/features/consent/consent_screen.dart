// User story: US-02 Privacy notice, consent and age check (Sprint 1, MVP)
// Requirements: FR-PROF-001, FR-PROF-010
// Implemented here: privacy disclosure, age policy confirmation (18+), and student consent recording without date of birth

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsentScreen extends StatefulWidget {
  static const String currentNoticeVersion = '1.0';

  final void Function({
    required String noticeVersion,
    required String timestamp,
    required bool ageCheckPassed,
  })? onConsent;

  final VoidCallback? onConsentCallback;
  final VoidCallback? onDecline;

  const ConsentScreen({
    super.key,
    this.onConsent,
    this.onConsentCallback,
    this.onDecline,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _ageConfirmed = false;
  bool _privacyAgreed = false;
  bool _showDeclineMessage = false;

  void _handleAgree() {
    if (!_ageConfirmed || !_privacyAgreed) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    widget.onConsent?.call(
      noticeVersion: ConsentScreen.currentNoticeVersion,
      timestamp: nowIso,
      ageCheckPassed: true,
    );
    widget.onConsentCallback?.call();
  }

  void _handleDecline() {
    setState(() {
      _showDeclineMessage = true;
    });
    widget.onDecline?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('consent_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('DevSphere Privacy Notice & Consent'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Privacy Notice',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('Version ${ConsentScreen.currentNoticeVersion}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to DevSphere. Before you create a profile or start your learning labs, '
                      'please review what information is collected and how it is used:',
                    ),
                    const SizedBox(height: 12),
                    const Text('• Identity: Account ID and email to authenticate your session.'),
                    const Text('• Profile: Display name and optional academic details (college, course, interests).'),
                    const Text('• Lab Progress: Attempt status, task completion timestamps, and code submissions.'),
                    const Text('• Evaluation: Automated grading results and feedback from the Grader.'),
                    const Text('• AI Tutor: Ephemeral question context to assist you in real time.'),
                    const Text('• Telemetry: Minimal, non-PII diagnostic logs to improve platform stability.'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Strict Data Minimization: DevSphere never asks for, collects, or stores '
                              'your date of birth, phone number, or government ID.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Age Verification (TBD-08)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The DevSphere MVP pilot is open only to students aged 18 and older. '
                      'Only the outcome of this confirmation is recorded.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      key: const Key('consent_age_checkbox'),
                      value: _ageConfirmed,
                      onChanged: (val) {
                        setState(() {
                          _ageConfirmed = val ?? false;
                          _showDeclineMessage = false;
                        });
                      },
                      title: const Text('I confirm that I am at least 18 years old.'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      key: const Key('consent_privacy_checkbox'),
                      value: _privacyAgreed,
                      onChanged: (val) {
                        setState(() {
                          _privacyAgreed = val ?? false;
                          _showDeclineMessage = false;
                        });
                      },
                      title: const Text(
                        'I have read and agree to the Privacy Notice (v1.0) and data processing terms.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_showDeclineMessage) ...[
                      const SizedBox(height: 12),
                      Container(
                        key: const Key('consent_decline_message'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Consent and age confirmation are required to use DevSphere. '
                          'Without consent, no profile or lab progress data will be collected.',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('consent_decline_button'),
                          onPressed: _handleDecline,
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          key: const Key('consent_agree_button'),
                          onPressed: (_ageConfirmed && _privacyAgreed) ? _handleAgree : null,
                          child: const Text('I Agree & Continue'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
