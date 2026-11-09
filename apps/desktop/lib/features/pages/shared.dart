// Capability: CAP-PROFILE-DATA, CAP-CATALOG. Tests: TC-PGS-01..
// Implemented here: what every rail page shares: the page frame (title, signed-out message, refresh of lab
// progress from VS Code) and the small status label that turns a person's progress into plain words.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../auth/auth_session.dart';
import '../dashboard/dashboard_data.dart';

class PageFrame extends ConsumerStatefulWidget {
  const PageFrame(
      {super.key,
      required this.slug,
      required this.title,
      required this.subtitle,
      required this.child});

  final String slug;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  ConsumerState<PageFrame> createState() => _PageFrameState();
}

class _PageFrameState extends ConsumerState<PageFrame> {
  @override
  void initState() {
    super.initState();
    // Progress made inside VS Code while this page was closed shows up when the page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        ref.read(userDataProvider).syncSessions(ref.read(workerClientProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final signedIn = AuthSession.instance.user != null;
    return SingleChildScrollView(
      key: Key('page-${widget.slug}'),
      padding: const EdgeInsets.all(BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: text.headlineMedium),
              const SizedBox(height: BL.space1),
              Text(widget.subtitle, style: text.bodySmall),
              const SizedBox(height: BL.space6),
              if (!signedIn) const SignedOutNotice() else widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

class SignedOutNotice extends StatelessWidget {
  const SignedOutNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('signed-out-notice'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: BL.textSecondary),
            const SizedBox(width: BL.space4),
            const Expanded(
              child: Text(
                  'Sign in to see your own courses, progress and credentials. Everything here belongs to your account only.'),
            ),
            FilledButton(
                onPressed: () => context.go('/'), child: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BL.space3, vertical: BL.space1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BL.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// The person's own status for one catalogue item, in plain words.
({String label, Color color}) statusFor(SampleActivity a, UserData? data) {
  if (!a.available) return (label: 'Coming soon', color: BL.textSecondary);
  final lab = data?.lab(a.id);
  switch (data?.statusOf(a.id) ?? LabStatus.notStarted) {
    case LabStatus.notStarted:
      return (label: 'Not started', color: BL.textSecondary);
    case LabStatus.inProgress:
      return (
        label: 'In progress: ${lab?.passed ?? 0} of ${lab?.total ?? 0} checks',
        color: BL.primary
      );
    case LabStatus.practiceComplete:
      return (label: 'Practice complete', color: BL.success);
  }
}

String actionFor(SampleActivity a, UserData? data) {
  if (!a.available) return 'Details';
  return switch (data?.statusOf(a.id) ?? LabStatus.notStarted) {
    LabStatus.notStarted => 'Open',
    LabStatus.inProgress => 'Resume',
    LabStatus.practiceComplete => 'Review',
  };
}

String shortDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}
