// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-PROG-001, NFR-USE-001
// Implemented here: dashboard in the Google-Skills pattern: hero card, Activities/Paths tabs with a
// card grid, and a right column (badges, skills, weekly goal, achievements). Progress, streak and goal come from
// the signed-in person's own saved results (lib/data); the course list is the catalogue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../auth/auth_session.dart';
import '../../ui/motion.dart';
import '../pages/credentials_screen.dart';
import '../pages/shared.dart';
import 'dashboard_data.dart';

/// Content width below which the right column is hidden.
const double _sideColumnMinContentWidth = 1100;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final showSide = box.maxWidth >= _sideColumnMinContentWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _Main()),
            if (showSide) const _SideColumn(),
          ],
        );
      },
    );
  }
}

class _Main extends StatefulWidget {
  const _Main();

  @override
  State<_Main> createState() => _MainState();
}

class _MainState extends State<_Main> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = _tab == 0
        ? SampleData.activities
        : SampleData.activities.where((a) => a.kinds.contains('Path')).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BL.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListenableBuilder(
            listenable: AuthSession.instance,
            builder: (context, _) {
              final u = AuthSession.instance.user;
              return Text(u == null ? 'Welcome to DevPilot' : 'Welcome, ${u.label}',
                  style: text.headlineMedium);
            },
          ),
          const SizedBox(height: BL.space1),
          Text('Your progress is saved for your account only, on this computer.',
              key: const Key('dashboard-caption'), style: text.bodySmall),
          const SizedBox(height: BL.space3),
          const Reveal(child: SizedBox(width: double.infinity, child: _Hero())),
          const SizedBox(height: BL.space6),
          Container(
            key: const Key('tabs'),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BL.border))),
            child: Row(
              children: [
                _Tab(
                    label: 'Activities',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0)),
                _Tab(
                    label: 'Paths',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
          const SizedBox(height: BL.space4),
          LayoutBuilder(
            builder: (context, box) {
              final cols =
                  box.maxWidth >= 900 ? 3 : (box.maxWidth >= 560 ? 2 : 1);
              final w = (box.maxWidth - (cols - 1) * BL.space4) / cols;
              return Wrap(
                spacing: BL.space4,
                runSpacing: BL.space4,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Reveal(
                      key: ValueKey('${_tab}-${items[i].id}'),
                      index: i + 1,
                      child: SizedBox(
                          width: w,
                          child: HoverLift(
                              child: _ActivityCard(index: i, item: items[i]))),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: BL.space6, vertical: BL.space3),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: selected ? BL.primary : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: selected ? BL.primary : BL.textSecondary),
        ),
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final resumeId = data?.resumable?.labId;
    final unit = SampleData.find(resumeId ?? '') ?? _recommended(data);
    final started = data?.lab(unit.id) != null;
    final path = SampleData.paths.where((p) => p.activityIds.contains(unit.id)).firstOrNull;
    return Card(
      key: const Key('hero'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Wrap(
          spacing: BL.space6,
          runSpacing: BL.space4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _HeroArt(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (path != null)
                    InkWell(
                      onTap: () => context.go('/paths'),
                      child: Text('Path: ${path.title}  ›',
                          style: text.bodyMedium?.copyWith(color: BL.primary)),
                    ),
                  const SizedBox(height: BL.space3),
                  Text(unit.title, style: text.titleLarge),
                  const SizedBox(height: BL.space4),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/course/${unit.id}'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(started ? 'Resume' : 'Start'),
                    style:
                        ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The first available lab the person has not finished, or the first lab when everything is done.
SampleActivity _recommended(UserData? data) {
  for (final a in SampleData.activities) {
    if (a.available && data?.statusOf(a.id) != LabStatus.practiceComplete) return a;
  }
  return SampleData.activities.first;
}

/// Simple original illustration (our own shapes, not Google's artwork).
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
          color: BL.selected, borderRadius: BorderRadius.circular(BL.radiusLg)),
      child: Stack(
        children: [
          Positioned(left: 24, top: 22, child: _block(86, 58, BL.surface)),
          Positioned(left: 70, top: 62, child: _block(96, 58, BL.primary)),
          const Positioned(
              left: 36,
              top: 36,
              child: Icon(Icons.terminal, size: 28, color: BL.primary)),
          const Positioned(
              left: 112,
              top: 76,
              child: Icon(Icons.call_merge, size: 30, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _block(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(BL.radiusMd),
            border: Border.all(color: BL.border)),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final featured = label == 'Featured';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BL.space2, vertical: 3),
      decoration: BoxDecoration(
        color: featured ? const Color(0xFFF3E8FD) : BL.surfaceMuted,
        borderRadius: BorderRadius.circular(BL.radiusSm),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: BL.textPrimary)),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.index, required this.item});

  final int index;
  final SampleActivity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final status = statusFor(item, ref.watch(userDataProvider).data);
    return Card(
      key: Key('activity-$index'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/course/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(BL.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                  spacing: BL.space2,
                  runSpacing: BL.space1,
                  children: [for (final k in item.kinds) _Chip(k)]),
              const SizedBox(height: BL.space4),
              Text(item.title,
                  style: text.titleLarge?.copyWith(fontSize: 19),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: BL.space2),
              Text(item.description,
                  style: text.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: BL.space4),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(label: status.label, color: status.color),
              ),
              const SizedBox(height: BL.space4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: BL.space2),
                  Expanded(child: Text(item.duration, style: text.bodySmall)),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: BL.selected, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward,
                        size: 18, color: BL.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideColumn extends ConsumerWidget {
  const _SideColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userDataProvider).data;
    return SizedBox(
      width: BL.sideColumnWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, BL.space8, BL.space8, BL.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Reveal(
              index: 2,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                    child: _CountCard(
                        cardKey: 'badges-card',
                        icon: Icons.workspace_premium_outlined,
                        label: 'Badges',
                        value: 0)),
                const SizedBox(width: BL.space4),
                Expanded(
                    child: _CountCard(
                        cardKey: 'skills-card',
                        icon: Icons.insights_outlined,
                        label: 'Skills',
                        value: practisedSkills(data).length)),
              ],
            )),
            const SizedBox(height: BL.space4),
            const Reveal(index: 3, child: _WeeklyCard()),
            const SizedBox(height: BL.space4),
            const Reveal(index: 4, child: _Achievements()),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard(
      {required this.cardKey,
      required this.icon,
      required this.label,
      required this.value});

  final String cardKey;
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: Key(cardKey),
      child: Padding(
        padding: const EdgeInsets.all(BL.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: BL.primary, size: 20),
              const SizedBox(width: BL.space2),
              Text(label, style: text.titleMedium)
            ]),
            const SizedBox(height: BL.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CountUp(
                    value: value,
                    style: text.headlineMedium?.copyWith(fontSize: 40)),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: BL.border)),
                  child: const Icon(Icons.arrow_forward, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCard extends ConsumerWidget {
  const _WeeklyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = ref.watch(userDataProvider);
    final data = c.data;
    final today = c.today;
    final week = data?.weekFlags(today) ?? List<bool>.filled(7, false);
    final labels = (data ?? const UserData(uid: '')).weekLabels(today);
    final done = data?.weeklyDone(today) ?? 0;
    final target = data?.weeklyTarget ?? 5;
    return Card(
      key: const Key('weekly-card'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CountUp(
                    value: done,
                    style: text.headlineMedium?.copyWith(fontSize: 56)),
                const SizedBox(width: BL.space3),
                const Icon(Icons.local_fire_department,
                    color: BL.warning, size: 36),
                const SizedBox(width: BL.space2),
                Expanded(
                    child: Text('of $target checks passed this week',
                        style: text.bodySmall)),
              ],
            ),
            const SizedBox(height: BL.space3),
            const Divider(),
            const SizedBox(height: BL.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Column(
                    children: [
                      Container(
                        key: Key('day-$i'),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: week[i]
                              ? BL.success
                              : Colors.transparent,
                          border: Border.all(
                              color: week[i]
                                  ? BL.success
                                  : BL.textDisabled,
                              width: 1.5),
                        ),
                        child: week[i]
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: BL.space1),
                      Text(labels[i], style: text.labelSmall),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievements extends ConsumerWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final labs = (data?.labs.values.toList() ?? [])..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    final shown = labs.take(2).toList();
    return Card(
      key: const Key('achievements'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: text.titleLarge),
            const SizedBox(height: BL.space1),
            Text(
                'A badge is earned only after a Verified result from the server.',
                style: text.bodySmall),
            const SizedBox(height: BL.space4),
            if (shown.isEmpty)
              Text('Open a lab from the list. Your progress will show here.',
                  key: const Key('achievements-empty'), style: text.bodyMedium)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: BL.space4),
                    Expanded(
                      child: _Medal(
                        title: SampleData.find(shown[i].labId)?.title ?? shown[i].title,
                        note: shown[i].status == LabStatus.practiceComplete
                            ? 'Practice complete, pending verification'
                            : '${shown[i].passed} of ${shown[i].total} checks',
                        value: shown[i].total == 0 ? 0 : shown[i].passed / shown[i].total,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.title, required this.note, required this.value});

  final String title;
  final String note;
  final double value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration:
              const BoxDecoration(color: BL.selected, shape: BoxShape.circle),
          child:
              const Icon(Icons.workspace_premium, size: 36, color: BL.primary),
        ),
        const SizedBox(height: BL.space2),
        Text(title, style: text.labelLarge, textAlign: TextAlign.center),
        Text(note, style: text.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: BL.space2),
        ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: AnimatedBar(value: value)),
      ],
    );
  }
}
