// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-GUIDE-001, NFR-USE-001
// Implemented here: the course page. A deep-blue banner with the title, the facts and the signed-in person's own progress
// and the Start or Resume button; below it what the lab is about, what you will do and the skills. Labs whose content is
// not installed say so and cannot be started.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
import 'start_lab_flow.dart';

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final userData = ref.watch(userDataProvider).data;
    final a = activityFor(widget.id, userData);
    final lab = userData?.lab(a.id);
    final progress = (lab?.score ?? 0) / 100;
    final facts = [
      a.level,
      a.duration,
      ...a.kinds.where((k) => k != 'Featured'),
      'Practice and Verified'
    ];
    final v = activityVisual(a.kinds);
    Widget fact(int i) => Container(
          key: Key('chip-$i'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20)),
          child: Text(facts[i],
              style: BL.mono(
                  size: 12, color: Colors.white, weight: FontWeight.w600)),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: BL.space8, vertical: BL.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: BL.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('course_back_button'),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Dashboard'),
                ),
              ),
              const SizedBox(height: BL.space2),
              Reveal(
                child: Container(
                  key: const Key('course-header'),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(BL.radiusXl),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [BL.heroStart, BL.heroEnd]),
                      boxShadow: BL.shadowLift),
                  padding: const EdgeInsets.all(BL.space8),
                  child: LayoutBuilder(builder: (context, box) {
                    final wide = box.maxWidth >= 760;
                    final left = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CATALOG  /  ${a.id.toUpperCase()}',
                              style: BL.mono(
                                  size: 11.5,
                                  color: Colors.white70,
                                  spacing: 1.2,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: BL.space3),
                          Text(a.title,
                              style: text.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.2)),
                          const SizedBox(height: BL.space4),
                          Wrap(
                              spacing: BL.space2,
                              runSpacing: BL.space2,
                              children: [
                                for (var i = 0; i < facts.length; i++) fact(i)
                              ]),
                        ]);
                    final right = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AsciiBar(
                              key: const Key('course-progress'),
                              value: progress,
                              color: Colors.white,
                              height: 8),
                          const SizedBox(height: BL.space2),
                          Text(
                              lab == null
                                  ? 'Not started'
                                  : '${lab.passed} of ${lab.total} checks  ·  ${lab.score}%',
                              style: BL.mono(size: 12, color: Colors.white70)),
                          const SizedBox(height: BL.space4),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: BL.heroStart,
                                disabledBackgroundColor: Colors.white24,
                                disabledForegroundColor: Colors.white60),
                            onPressed: _busy != null || !a.available
                                ? null
                                : () =>
                                    startLab(context, ref, a.id, onBusy: (l) {
                                      if (mounted) setState(() => _busy = l);
                                    }),
                            child: Text(_busy ??
                                (!a.available
                                    ? 'Coming soon'
                                    : (lab == null ? 'Start' : 'Resume'))),
                          ),
                        ]);
                    if (!wide)
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            left,
                            const SizedBox(height: BL.space6),
                            right
                          ]);
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: BL.space8),
                          SizedBox(width: 300, child: right)
                        ]);
                  }),
                ),
              ),
              const SizedBox(height: BL.space8),
              Reveal(
                index: 1,
                child: Panel(
                  padding: const EdgeInsets.all(BL.space6),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(
                            icon: v.icon,
                            tint: v.tint,
                            color: v.color,
                            size: 44),
                        const SizedBox(width: BL.space4),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('About this lab', style: text.titleMedium),
                                const SizedBox(height: BL.space2),
                                Text(a.description,
                                    style:
                                        text.bodyLarge?.copyWith(height: 1.6)),
                                const SizedBox(height: BL.space3),
                                Text(
                                    'Sample data: the outline below is a summary. Your progress is real. Practice results stay on this computer; a badge needs a Verified result from the server.',
                                    style: BL.mono(size: 12)),
                              ]),
                        ),
                      ]),
                ),
              ),
              if (a.steps.isNotEmpty) ...[
                const SizedBox(height: BL.space8),
                Reveal(
                  index: 2,
                  child: Section(
                    label: 'What you will do',
                    child: LayoutBuilder(builder: (context, box) {
                      final cols = box.maxWidth >= 900
                          ? 3
                          : (box.maxWidth >= 560 ? 2 : 1);
                      final w = (box.maxWidth - BL.space4 * (cols - 1)) / cols;
                      return Wrap(
                          spacing: BL.space4,
                          runSpacing: BL.space4,
                          children: [
                            for (var i = 0; i < a.steps.length; i++)
                              SizedBox(
                                width: w,
                                child: Panel(
                                  padding: const EdgeInsets.all(BL.space4),
                                  child: Row(children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: BL.primarySoft,
                                          shape: BoxShape.circle),
                                      child: Text('${i + 1}',
                                          style: BL.mono(
                                              size: 14,
                                              color: BL.primary,
                                              weight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: BL.space3),
                                    Expanded(
                                        child: Text(a.steps[i],
                                            style: text.titleSmall)),
                                  ]),
                                ),
                              ),
                          ]);
                    }),
                  ),
                ),
              ],
              if (a.skills.isNotEmpty) ...[
                const SizedBox(height: BL.space8),
                Reveal(
                  index: 3,
                  child: Section(
                      label: 'Skills you will practise',
                      child: Wrap(
                          spacing: BL.space2,
                          runSpacing: BL.space2,
                          children: [
                            for (final s in a.skills) Tag(s, tone: Tone.info)
                          ])),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
