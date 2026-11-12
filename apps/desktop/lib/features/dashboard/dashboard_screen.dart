// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-PROG-001, NFR-USE-001
// Implemented here: the dashboard. A deep-blue "continue" card for the lab in progress, the lab cards (Activities and
// Paths tabs), and a side column with badges, skills, the week at a glance and the person's path as a timeline. Everything
// shown is the signed-in person's own saved results (lib/data); the lab list is the catalogue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../auth/auth_session.dart';
import '../pages/activity_table.dart';
import '../pages/credentials_screen.dart';
import 'dashboard_data.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

String greetingFor(DateTime now) => now.hour < 12
    ? 'Good morning'
    : (now.hour < 18 ? 'Good afternoon' : 'Good evening');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(userDataProvider);
    final data = c.data;
    final now = c.today;
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (context, _) {
        final user = AuthSession.instance.user;
        final first = user == null ? '' : user.label.split(' ').first;
        return SingleChildScrollView(
          key: const Key('page-dashboard'),
          padding: const EdgeInsets.symmetric(
              horizontal: BL.space8, vertical: BL.space8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: BL.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: PageHead(
                      label:
                          '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                      title: first.isEmpty
                          ? 'Welcome to DevPilot'
                          : '${greetingFor(now)}, $first',
                      description:
                          'Your progress is saved for your account only, on this computer.',
                    ),
                  ),
                  const SizedBox(height: BL.space8),
                  LayoutBuilder(builder: (context, box) {
                    final main = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Reveal(index: 1, child: _Resume(data: data)),
                          const SizedBox(height: BL.space12),
                          Reveal(index: 2, child: const _Learn()),
                        ]);
                    final side = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Reveal(index: 2, child: _Stats(data: data)),
                          const SizedBox(height: BL.space4),
                          Reveal(
                              index: 3, child: _Week(data: data, today: now)),
                          const SizedBox(height: BL.space4),
                          Reveal(index: 4, child: _Path(data: data)),
                        ]);
                    if (box.maxWidth < 1100)
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            main,
                            const SizedBox(height: BL.space8),
                            side
                          ]);
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: main),
                          const SizedBox(width: BL.space8),
                          SizedBox(width: BL.sideColumnWidth, child: side)
                        ]);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The first available lab the person has not finished, or the first lab when everything is done.
SampleActivity recommendedActivity(UserData? data) {
  for (final a in SampleData.activities) {
    if (a.available && data?.statusOf(a.id) != LabStatus.practiceComplete)
      return a;
  }
  return SampleData.activities.first;
}

// ------------------------------------------------------------------------------------------------ continue card

class _Resume extends StatelessWidget {
  const _Resume({required this.data});

  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final resumeId = data?.resumable?.labId;
    final unit = SampleData.find(resumeId ?? '') ?? recommendedActivity(data);
    final lab = data?.lab(unit.id);
    final started = lab != null;
    final path = SampleData.paths
        .where((p) => p.activityIds.contains(unit.id))
        .firstOrNull;
    final progress =
        lab == null || lab.total == 0 ? 0.0 : lab.passed / lab.total;
    Widget fact(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: BL.mono(
                  size: 12, color: Colors.white, weight: FontWeight.w600)),
        );
    return Container(
      key: const Key('hero'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BL.radiusXl),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BL.heroStart, BL.heroEnd]),
        boxShadow: BL.shadowLift,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BL.radiusXl),
        child: CustomPaint(
          painter: _RingsPainter(),
          child: Padding(
            padding: const EdgeInsets.all(BL.space8),
            child: LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 620;
              final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(started ? 'CONTINUE WHERE YOU LEFT OFF' : 'START HERE',
                        style: BL.mono(
                            size: 11.5,
                            color: Colors.white70,
                            spacing: 1.4,
                            weight: FontWeight.w700)),
                    const SizedBox(height: BL.space3),
                    if (path != null)
                      InkWell(
                          onTap: () => context.go('/paths'),
                          child: Text('${path.title}  ›',
                              style:
                                  BL.mono(size: 12.5, color: Colors.white70))),
                    if (path != null) const SizedBox(height: 6),
                    Text(unit.title,
                        style: text.headlineSmall?.copyWith(
                            color: Colors.white, fontSize: 26, height: 1.2)),
                    const SizedBox(height: BL.space3),
                    Text(unit.description,
                        style: text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: BL.space6),
                    Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
                      fact(unit.duration),
                      fact(unit.level),
                      if (lab != null)
                        fact('${lab.passed} of ${lab.total} checks')
                    ]),
                    const SizedBox(height: BL.space6),
                    FilledButton.icon(
                      key: const Key('hero-action'),
                      style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: BL.heroStart)
                          .copyWith(
                        backgroundColor:
                            const WidgetStatePropertyAll(Colors.white),
                        foregroundColor: WidgetStatePropertyAll(BL.heroStart),
                      ),
                      onPressed: () => context.go('/course/${unit.id}'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(started ? 'Resume' : 'Start'),
                    ),
                  ]);
              final ring = ProgressRing(
                value: progress,
                size: 132,
                stroke: 11,
                color: Colors.white,
                track: Colors.white.withValues(alpha: 0.2),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(progress * 100).round()}%',
                      style: text.headlineSmall
                          ?.copyWith(color: Colors.white, fontSize: 28)),
                  Text(started ? 'done' : 'ready',
                      style: BL.mono(size: 12, color: Colors.white70)),
                ]),
              );
              if (!wide) return left;
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: BL.space8),
                    ring
                  ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// Soft concentric rings in the corner of the continue card, for depth.
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.07);
    final c = Offset(size.width * 0.92, size.height * 0.08);
    for (var r = 90.0; r < 420; r += 56) {
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

// ------------------------------------------------------------------------------------------------ learn

class _Learn extends ConsumerStatefulWidget {
  const _Learn();

  @override
  ConsumerState<_Learn> createState() => _LearnState();
}

class _LearnState extends ConsumerState<_Learn> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(userDataProvider).data;
    final items = _tab == 0
        ? SampleData.activities
        : SampleData.activities.where((a) => a.kinds.contains('Path')).toList();
    return Section(
      label: 'Learn',
      trailing: PillTabs(
          key: const Key('tabs'),
          labels: const ['Activities', 'Paths'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i)),
      child: ActivityTable(items: items, data: data, maxColumns: 3),
    );
  }
}

// ------------------------------------------------------------------------------------------------ side column

class _Stats extends StatelessWidget {
  const _Stats({required this.data});

  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final skills = practisedSkills(data).length;
    Widget tile(String key, IconData icon, Color tint, Color color, int value,
            String label) =>
        Expanded(
          child: Panel(
            key: Key(key),
            padding: const EdgeInsets.all(BL.space4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(icon: icon, tint: tint, color: color, size: 38),
              const SizedBox(height: BL.space3),
              CountUp(
                  value: value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 30)),
              const SizedBox(height: 2),
              Text(label, style: BL.mono(size: 12)),
            ]),
          ),
        );
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      tile('badges-card', Icons.workspace_premium_outlined, BL.tintViolet,
          BL.violet, 0, 'Verified badges'),
      const SizedBox(width: BL.space4),
      tile('skills-card', Icons.insights_outlined, BL.tintTeal, BL.teal, skills,
          'Skills practised'),
    ]);
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.data, required this.today});

  final UserData? data;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = data?.weeklyDone(today) ?? 0;
    final target = data?.weeklyTarget ?? 5;
    final streak = data?.streakWeeks(today) ?? 0;
    final counts = data?.dayCounts(today, 7) ?? List<int>.filled(7, 0);
    final labels = (data ?? const UserData(uid: '')).weekLabels(today);
    return Panel(
      key: const Key('weekly-card'),
      title: 'This week',
      padding: const EdgeInsets.all(BL.space6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ProgressRing(
            value: target == 0 ? 0 : done / target,
            size: 84,
            stroke: 9,
            color: done >= target ? BL.success : BL.primary,
            child: Text('$done/$target',
                key: const Key('week-line'), style: text.titleMedium),
          ),
          const SizedBox(width: BL.space4),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('checks passed', style: text.titleSmall),
              const SizedBox(height: 4),
              Row(key: const Key('streak-line'), children: [
                Icon(Icons.local_fire_department,
                    size: 16, color: streak > 0 ? BL.amber : BL.textDisabled),
                const SizedBox(width: 4),
                Text('$streak week${streak == 1 ? '' : 's'} in a row',
                    style: BL.mono(size: 12)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: BL.space6),
        WeekBars(values: counts, labels: labels, keyPrefix: 'day'),
      ]),
    );
  }
}

class _Path extends StatelessWidget {
  const _Path({required this.data});

  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final resume = data?.resumable?.labId ?? recommendedActivity(data).id;
    final path = SampleData.paths
            .where((p) => p.activityIds.contains(resume))
            .firstOrNull ??
        SampleData.paths.first;
    final items = [for (final id in path.activityIds) SampleData.find(id)]
        .whereType<SampleActivity>()
        .toList();
    var head = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i].available &&
          data?.statusOf(items[i].id) != LabStatus.practiceComplete) {
        head = i;
        break;
      }
    }
    final done = items
        .where((a) =>
            a.available && data?.statusOf(a.id) == LabStatus.practiceComplete)
        .length;
    return Panel(
      key: const Key('achievements'),
      title: 'Your path',
      trailing: Text('$done of ${items.length} done', style: BL.mono(size: 12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(path.title, style: text.titleMedium),
        const SizedBox(height: BL.space4),
        for (var i = 0; i < items.length; i++)
          GitNode(
            first: i == 0,
            last: i == items.length - 1,
            state: !items[i].available
                ? NodeState.later
                : (data?.statusOf(items[i].id) == LabStatus.practiceComplete
                    ? NodeState.done
                    : (i == head ? NodeState.head : NodeState.todo)),
            child: InkWell(
              key: Key('roadmap-node-${items[i].id}'),
              onTap: items[i].available
                  ? () => context.go('/course/${items[i].id}')
                  : null,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(items[i].title,
                        style: text.bodyMedium?.copyWith(
                            color: items[i].available
                                ? BL.textPrimary
                                : BL.textSecondary,
                            fontWeight:
                                i == head ? FontWeight.w700 : FontWeight.w500)),
                    const SizedBox(height: 2),
                    Row(children: [
                      statusTag(items[i], data),
                      if (i == head) ...[
                        const SizedBox(width: 6),
                        const Tag('Up next', tone: Tone.info)
                      ]
                    ]),
                  ]),
            ),
          ),
      ]),
    );
  }
}
