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
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
import 'interview_card.dart';
import 'shared.dart';

class RoadmapPlanner extends ConsumerStatefulWidget {
  const RoadmapPlanner({super.key});

  @override
  ConsumerState<RoadmapPlanner> createState() => _RoadmapPlannerState();
}

class _RoadmapPlannerState extends ConsumerState<RoadmapPlanner> {
  final _text = TextEditingController();
  String _kind = 'job_description';
  String _level = 'beginner';
  bool _busy = false;
  String _what = 'roadmap';
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run(String what) async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = _kind == 'job_description'
          ? 'Paste a job description first.'
          : 'Type a topic first.');
      return;
    }
    setState(() {
      _busy = true;
      _what = what;
      _error = null;
    });
    try {
      final api = ref.read(devPilotApiProvider);
      final controller = ref.read(userDataProvider);
      if (what == 'roadmap') {
        final raw = await api.roadmap(kind: _kind, text: text, level: _level);
        final saved =
            SavedRoadmap.fromApi(raw, source: _kind, now: controller.today);
        if (saved == null) {
          throw const ApiProblem('The planner gave an answer we could not use.',
              recovery: 'Try again with a shorter or clearer request.');
        }
        controller.saveRoadmap(saved);
      } else {
        final raw = await api.interview(kind: _kind, text: text, level: _level);
        final saved = SavedInterview.parse(raw,
            source: _kind, createdAt: controller.today.toIso8601String());
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          key: const Key('roadmap-planner'),
          title: 'Plan a roadmap or practise interviews',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            PillTabs(
                key: const Key('planner-kind'),
                labels: const ['Job description', 'Topic'],
                selected: _kind == 'job_description' ? 0 : 1,
                enabled: !_busy,
                onChanged: (i) => setState(
                    () => _kind = i == 0 ? 'job_description' : 'topic')),
            const SizedBox(width: BL.space3),
            PillTabs(
                key: const Key('planner-level'),
                labels: const ['Beginner', 'Intermediate'],
                selected: _level == 'beginner' ? 0 : 1,
                enabled: !_busy,
                onChanged: (i) => setState(
                    () => _level = i == 0 ? 'beginner' : 'intermediate')),
          ]),
          padding: const EdgeInsets.all(BL.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  'Paste a job description and get a path of real labs to prepare for it, or a set of interview questions. Written by Gemini, checked by DevPilot.',
                  style: text.bodySmall),
              const SizedBox(height: BL.space4),
              TextField(
                key: const Key('planner-text'),
                controller: _text,
                enabled: !_busy,
                minLines: 4,
                maxLines: 8,
                maxLength: 6000,
                style: text.bodyMedium,
                decoration: InputDecoration(
                  counterStyle: BL.mono(size: 11, color: BL.textDisabled),
                  hintText: _kind == 'job_description'
                      ? 'Paste the job description here...'
                      : 'For example: backend development with Python and FastAPI',
                  hintStyle: text.bodyMedium?.copyWith(color: BL.textDisabled),
                ),
              ),
              const SizedBox(height: BL.space2),
              Row(children: [
                FilledButton(
                  key: const Key('planner-submit'),
                  onPressed: _busy ? null : () => _run('roadmap'),
                  child: Text(_busy && _what == 'roadmap'
                      ? 'Planning (about 15 seconds)...'
                      : 'Plan my roadmap'),
                ),
                const SizedBox(width: BL.space2),
                OutlinedButton(
                  key: const Key('planner-interview'),
                  onPressed: _busy ? null : () => _run('interview'),
                  child: Text(_busy && _what == 'interview'
                      ? 'Writing questions...'
                      : 'Interview questions'),
                ),
                const SizedBox(width: BL.space4),
                Expanded(
                    child: Text(
                        'Sent to the DevPilot service with passwords and keys removed.',
                        style: BL.mono(size: 12, color: BL.textSecondary))),
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
                    Icon(Icons.error_outline, color: BL.danger, size: 20),
                    const SizedBox(width: BL.space3),
                    Expanded(child: Text(_error!, style: text.bodyMedium))
                  ]),
                ),
              ],
            ],
          ),
        ),
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
