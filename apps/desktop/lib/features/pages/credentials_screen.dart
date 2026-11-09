// Capability: CAP-CREDENTIALS. Rules: TRU-01, TRU-02. Tests: TC-PGS-04..
// Implemented here: the signed-in person's own credentials. A badge is only ever awarded from a Verified result
// from the server, and verification is not connected in this version, so this page shows Practice results
// honestly: finished labs are "Practice complete, pending verification" and the badge count is 0.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../auth/auth_session.dart';
import '../dashboard/dashboard_data.dart';
import '../../ui/motion.dart';
import 'shared.dart';

String practiceLevel(int completedLabs) {
  if (completedLabs >= 3) return 'Practitioner (practice)';
  if (completedLabs >= 1) return 'Foundations (practice)';
  return 'Getting started';
}

/// Skills from the finished labs, without repeats, in the order they were earned.
List<String> practisedSkills(UserData? data) {
  final out = <String>[];
  for (final l in data?.completed.reversed ?? const <LabProgress>[]) {
    for (final s in SampleData.find(l.labId)?.skills ?? const <String>[]) {
      if (!out.contains(s)) out.add(s);
    }
  }
  return out;
}

class CredentialsScreen extends ConsumerWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    final user = AuthSession.instance.user;
    final text = Theme.of(context).textTheme;
    final done = data?.completed ?? const <LabProgress>[];
    final skills = practisedSkills(data);
    final inProgress = (data?.labs.values
            .where((l) => l.status == LabStatus.inProgress)
            .toList() ??
        [])
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return PageFrame(
      slug: 'credentials',
      title: 'Credentials',
      subtitle: user == null
          ? 'Your badges and skill levels.'
          : 'Credentials of ${user.label}. Only you can see this page.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: BL.space4,
            runSpacing: BL.space4,
            children: [
              Reveal(
                  index: 0,
                  child: _Stat(
                      key: const Key('stat-level'),
                      label: 'Practice level',
                      value: practiceLevel(done.length))),
              Reveal(
                  index: 1,
                  child: _Stat(
                      key: const Key('stat-badges'),
                      label: 'Verified badges',
                      value: '0')),
              Reveal(
                  index: 2,
                  child: _Stat(
                      key: const Key('stat-completed'),
                      label: 'Labs completed (practice)',
                      value: '${done.length}')),
              Reveal(
                  index: 3,
                  child: _Stat(
                      key: const Key('stat-skills'),
                      label: 'Skills practised',
                      value: '${skills.length}')),
            ],
          ),
          const SizedBox(height: BL.space4),
          Container(
            key: const Key('verification-note'),
            padding: const EdgeInsets.all(BL.space4),
            decoration: BoxDecoration(
                color: BL.selected,
                borderRadius: BorderRadius.circular(BL.radiusMd)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: BL.primary, size: 20),
                const SizedBox(width: BL.space3),
                Expanded(
                  child: Text(
                    'A badge is awarded only when the DevPilot server verifies your result. Verification is not connected in this version, '
                    'so your completed labs are saved as Practice results. They will be submitted for verification when that is available.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BL.space6),
          Text('Completed labs', style: text.titleLarge),
          const SizedBox(height: BL.space3),
          if (done.isEmpty)
            _Empty(
                key: const Key('credentials-empty'),
                message:
                    'You have not completed a lab yet. When all of a lab\'s checks pass, it appears here.',
                action: 'Browse the catalog',
                route: '/catalog')
          else
            for (var i = 0; i < done.length; i++)
              Reveal(
                  index: i + 4,
                  child: Card(
                    key: Key('completed-${done[i].labId}'),
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: BL.success),
                      title: Text(SampleData.find(done[i].labId)?.title ??
                          done[i].title),
                      subtitle: Text(
                          'Completed ${shortDate(done[i].completedAt ?? done[i].lastActivity)} · score ${done[i].score}%'),
                      trailing: const StatusChip(
                          label: 'Pending verification', color: BL.warning),
                    ),
                  )),
          if (inProgress.isNotEmpty) ...[
            const SizedBox(height: BL.space6),
            Text('In progress', style: text.titleLarge),
            const SizedBox(height: BL.space3),
            for (final l in inProgress)
              Card(
                key: Key('inprogress-${l.labId}'),
                child: ListTile(
                  leading: const Icon(Icons.timelapse, color: BL.primary),
                  title: Text(SampleData.find(l.labId)?.title ?? l.title),
                  subtitle: Text('${l.passed} of ${l.total} checks passed'),
                  trailing: OutlinedButton(
                      onPressed: () => context.go('/course/${l.labId}'),
                      child: const Text('Resume')),
                ),
              ),
          ],
          const SizedBox(height: BL.space6),
          Text('Skills you have practised', style: text.titleLarge),
          const SizedBox(height: BL.space3),
          if (skills.isEmpty)
            Text('Skills appear here after you complete a lab.',
                style: text.bodyMedium)
          else
            Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
              for (final s in skills) StatusChip(label: s, color: BL.navy)
            ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(BL.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.headlineSmall),
              const SizedBox(height: BL.space1),
              Text(label, style: text.bodySmall)
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(
      {super.key,
      required this.message,
      required this.action,
      required this.route});

  final String message;
  final String action;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            OutlinedButton(
                onPressed: () => context.go(route), child: Text(action)),
          ],
        ),
      ),
    );
  }
}
