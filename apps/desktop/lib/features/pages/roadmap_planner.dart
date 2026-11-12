// Capability: CAP-ROADMAP, CAP-AI-CLIENT. Rules: TRU-01, AIR-01, AIR-08. Tests: TC-AIUI-01..
// Implemented here: "Build a roadmap for a job or topic". The person pastes a job description (or names a topic); the
// DevPilot API asks Gemini and answers with a path made only of labs that exist, plus a few labs that do not exist yet.
// The roadmap is drawn as a git graph and saved with this person's own data. The app never calls Gemini itself.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/fx.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
import '../learn/path_builder.dart' show MyPathsSection;
import '../tutor/tutor_panel.dart' show tutorLanguageProvider, tutorLanguages;
import 'interview_card.dart';
import 'shared.dart';

class RoadmapPlanner extends ConsumerStatefulWidget {
  const RoadmapPlanner({super.key});

  @override
  ConsumerState<RoadmapPlanner> createState() => _RoadmapPlannerState();
}

/// A pasted job description is long or has several lines; a short single line is a topic.
String inferKind(String text) {
  final t = text.trim();
  return (t.length > 240 || t.contains('\n')) ? 'job_description' : 'topic';
}

class _RoadmapPlannerState extends ConsumerState<RoadmapPlanner> {
  final _text = TextEditingController();
  String _level = 'beginner';
  bool _busy = false;
  String _what = 'path';
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run(String what) async {
    final text = _text.text.trim();
    if (text.isEmpty || (what == 'path' && text.length < 3)) {
      setState(() => _error =
          'Type what you want to learn, or paste a job description, first.');
      return;
    }
    setState(() {
      _busy = true;
      _what = what;
      _error = null;
    });
    final kind = inferKind(text);
    final language = ref.read(tutorLanguageProvider);
    try {
      final api = ref.read(devPilotApiProvider);
      final controller = ref.read(userDataProvider);
      if (what == 'path') {
        final raw =
            await api.createPath(goal: text, level: _level, language: language);
        final now = controller.today;
        final path = StudyPath.fromApi(raw,
            id: 'p${now.millisecondsSinceEpoch}',
            goal: text,
            level: _level,
            language: language,
            now: now);
        if (path == null) {
          throw const ApiProblem(
              'The path came back in a shape DevPilot cannot use.',
              recovery: 'Try again.');
        }
        controller.addPath(path);
        _text.clear();
        if (mounted) context.go('/learn/${path.id}');
        return;
      } else if (what == 'roadmap') {
        final raw = await api.roadmap(kind: kind, text: text, level: _level);
        final saved =
            SavedRoadmap.fromApi(raw, source: kind, now: controller.today);
        if (saved == null) {
          throw const ApiProblem('The planner gave an answer we could not use.',
              recovery: 'Try again with a shorter or clearer request.');
        }
        controller.saveRoadmap(saved);
      } else {
        final raw = await api.interview(kind: kind, text: text, level: _level);
        final saved = SavedInterview.parse(raw,
            source: kind, createdAt: controller.today.toIso8601String());
        if (saved == null) {
          throw const ApiProblem('The coach gave an answer we could not use.',
              recovery: 'Try again with a shorter or clearer request.');
        }
        controller.saveInterview(saved);
      }
      if (mounted) setState(() => _text.clear());
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final saved = data?.roadmap;
    final interview = data?.interview;
    final language = ref.watch(tutorLanguageProvider);
    final typed = _text.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlowFrame(
          child: Panel(
            key: const Key('roadmap-planner'),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(BL.radiusCard)),
                  child: AuroraBackdrop(
                    radius: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          BL.space8, BL.space6, BL.space6, BL.space6),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LEARN ANYTHING',
                                    style: BL.mono(
                                        size: 11.5,
                                        color: Colors.white70,
                                        spacing: 1.6,
                                        weight: FontWeight.w700)),
                                const SizedBox(height: BL.space2),
                                Text('What do you want to learn?',
                                    style: text.headlineSmall?.copyWith(
                                        color: Colors.white, fontSize: 26)),
                                const SizedBox(height: BL.space2),
                                Text(
                                  'Name a topic or a goal, or paste a job description. DevPilot builds a step-by-step path: '
                                  'an explanation, videos you watch here, a quick check and a lab for each step, and the next '
                                  'step opens when you finish one. It can also plan a roadmap from the ready-made labs or '
                                  'write interview questions.',
                                  style: text.bodyMedium?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.82)),
                                ),
                              ]),
                        ),
                        const SizedBox(width: BL.space6),
                        const IsoStack(size: 150),
                      ]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BL.space6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: BL.space4),
                      TextField(
                        key: const Key('planner-text'),
                        controller: _text,
                        enabled: !_busy,
                        minLines: 2,
                        maxLines: 8,
                        maxLength: 6000,
                        onChanged: (_) => setState(() {}),
                        style: text.bodyMedium,
                        decoration: InputDecoration(
                          counterStyle:
                              BL.mono(size: 11, color: BL.textDisabled),
                          hintText:
                              'For example: understand how Git branches work, or become a junior Python backend developer. '
                              'You can also paste a whole job description.',
                          hintStyle:
                              text.bodyMedium?.copyWith(color: BL.textDisabled),
                        ),
                      ),
                      if (typed.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            inferKind(typed) == 'topic'
                                ? 'Treated as a topic or goal.'
                                : 'Treated as a job description.',
                            key: const Key('planner-kind-note'),
                            style: BL.mono(size: 11.5, color: BL.textSecondary),
                          ),
                        ),
                      const SizedBox(height: BL.space3),
                      Wrap(
                          spacing: BL.space3,
                          runSpacing: BL.space3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PillTabs(
                                key: const Key('planner-level'),
                                labels: const ['Beginner', 'Intermediate'],
                                selected: _level == 'beginner' ? 0 : 1,
                                enabled: !_busy,
                                onChanged: (i) => setState(() => _level =
                                    i == 0 ? 'beginner' : 'intermediate')),
                            DropdownButton<String>(
                              key: const Key('path-language'),
                              value: language,
                              isDense: true,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (final e in tutorLanguages.entries)
                                  DropdownMenuItem(
                                      value: e.key, child: Text(e.value)),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (v) => ref
                                      .read(tutorLanguageProvider.notifier)
                                      .state = v ?? 'en',
                            ),
                          ]),
                      const SizedBox(height: BL.space3),
                      Wrap(
                          spacing: BL.space2,
                          runSpacing: BL.space2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              key: const Key('path-create'),
                              onPressed: _busy ? null : () => _run('path'),
                              icon: _busy && _what == 'path'
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome, size: 18),
                              label: Text(_busy && _what == 'path'
                                  ? 'Planning your path...'
                                  : 'Build my learning path'),
                            ),
                            OutlinedButton(
                              key: const Key('planner-submit'),
                              onPressed: _busy ? null : () => _run('roadmap'),
                              child: Text(_busy && _what == 'roadmap'
                                  ? 'Planning (about 15 seconds)...'
                                  : 'Plan my roadmap'),
                            ),
                            OutlinedButton(
                              key: const Key('planner-interview'),
                              onPressed: _busy ? null : () => _run('interview'),
                              child: Text(_busy && _what == 'interview'
                                  ? 'Writing questions...'
                                  : 'Interview questions'),
                            ),
                            Text(
                                'Sent to the DevPilot service with passwords and keys removed.',
                                style:
                                    BL.mono(size: 12, color: BL.textSecondary)),
                          ]),
                      if (_error != null) ...[
                        const SizedBox(height: BL.space4),
                        Container(
                          key: const Key('planner-error'),
                          padding: const EdgeInsets.all(BL.space3),
                          decoration: BoxDecoration(
                              color: BL.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(BL.radiusMd)),
                          child: Row(children: [
                            Icon(Icons.error_outline,
                                color: BL.danger, size: 20),
                            const SizedBox(width: BL.space3),
                            Expanded(
                                child: Text(_error!, style: text.bodyMedium))
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BL.space8),
        const MyPathsSection(),
        if (saved != null) ...[
          const SizedBox(height: BL.space12),
          Reveal(
              key: ValueKey(saved.createdAt),
              child: _SavedRoadmap(roadmap: saved)),
        ],
        if (interview != null) ...[
          const SizedBox(height: BL.space12),
          Reveal(
              key: ValueKey('i-${interview.createdAt}'),
              child: InterviewCard(interview: interview)),
        ],
      ],
    );
  }
}

class _SavedRoadmap extends ConsumerWidget {
  const _SavedRoadmap({required this.roadmap});

  final SavedRoadmap roadmap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final labSteps = roadmap.steps.where((s) => s.kind == 'lab').toList();
    final done = labSteps
        .where((s) => data?.statusOf(s.labId!) == LabStatus.practiceComplete)
        .length;
    var head = -1;
    for (var i = 0; i < roadmap.steps.length; i++) {
      final s = roadmap.steps[i];
      if (s.kind == 'lab' &&
          data?.statusOf(s.labId!) != LabStatus.practiceComplete) {
        head = i;
        break;
      }
    }
    return Container(
      key: const Key('saved-roadmap'),
      child: Section(
        label: 'Your roadmap',
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
              roadmap.source == 'topic'
                  ? 'From a topic'
                  : 'From a job description',
              style: BL.mono(size: 12)),
          const SizedBox(width: BL.space3),
          InkWell(
              key: const Key('roadmap-clear'),
              onTap: () => ref.read(userDataProvider).clearRoadmap(),
              child: Text('Remove',
                  style: BL.mono(size: 12, color: BL.textSecondary))),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(roadmap.title, style: text.headlineSmall),
          const SizedBox(height: BL.space1),
          Text(
              labSteps.isEmpty
                  ? 'No ready-made lab matches yet.'
                  : '$done of ${labSteps.length} ready-made labs done',
              style: BL.mono(size: 12)),
          const SizedBox(height: BL.space6),
          for (var i = 0; i < roadmap.steps.length; i++)
            _Step(
                index: i,
                step: roadmap.steps[i],
                data: data,
                first: i == 0,
                last: i == roadmap.steps.length - 1,
                head: i == head),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.index,
      required this.step,
      required this.data,
      required this.first,
      required this.last,
      required this.head});

  final int index;
  final RoadmapStepData step;
  final UserData? data;
  final bool first;
  final bool last;
  final bool head;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLab = step.kind == 'lab';
    final activity = isLab ? SampleData.find(step.labId!) : null;
    final complete =
        isLab && data?.statusOf(step.labId!) == LabStatus.practiceComplete;
    return GitNode(
      first: first,
      last: last,
      state: !isLab
          ? NodeState.later
          : (complete
              ? NodeState.done
              : (head ? NodeState.head : NodeState.todo)),
      child: Container(
        key: Key('roadmap-step-$index'),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity?.title ?? step.title,
                  style: text.titleSmall?.copyWith(
                      color: isLab ? BL.textPrimary : BL.textSecondary)),
              if (step.why.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(step.why, style: text.bodySmall)),
              if (step.skills.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        step.skills.map((s) => s.toLowerCase()).join('  ·  '),
                        style: BL.mono(size: 11, color: BL.textDisabled))),
            ]),
          ),
          const SizedBox(width: BL.space4),
          if (isLab && activity != null)
            TextButton(
                onPressed: () => context.go('/course/${step.labId}'),
                child: Text(actionFor(activity, data)))
          else
            Text('No lab yet',
                style: BL.mono(size: 11.5, color: BL.textDisabled)),
        ]),
      ),
    );
  }
}
