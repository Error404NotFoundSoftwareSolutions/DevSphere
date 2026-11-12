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
import '../../ui/kit.dart';
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
    final signedIn = AuthSession.instance.user != null;
    return SingleChildScrollView(
      key: Key('page-${widget.slug}'),
      padding: const EdgeInsets.symmetric(
          horizontal: BL.space8, vertical: BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: BL.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHead(
                  label: '~/${widget.slug}',
                  title: widget.title,
                  description: widget.subtitle),
              const SizedBox(height: BL.space8),
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
    return Panel(
      key: const Key('signed-out-notice'),
      title: 'sign in required',
      child: Row(
        children: [
          Expanded(
              child: Text(
                  'Sign in to see your own labs, progress and credentials. Everything here belongs to your account only.',
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: BL.space4),
          FilledButton(
              onPressed: () => context.go('/'), child: const Text('Sign in')),
        ],
      ),
    );
  }
}

/// Status and labels as plain coloured mono text (the terminal-native look). The old name is kept so every page
/// that shows a status gets the new style: the colour passed in picks the tone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  Tone get _tone {
    if (color == BL.success || color == BL.primary) return Tone.accent;
    if (color == BL.warning) return Tone.warn;
    if (color == BL.danger) return Tone.bad;
    if (color == BL.info) return Tone.info;
    return Tone.muted;
  }

  @override
  Widget build(BuildContext context) => Tag(label, tone: _tone);
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
