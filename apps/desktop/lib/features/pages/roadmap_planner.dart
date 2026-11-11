// Capability: CAP-ROADMAP, CAP-AI-CLIENT. Rules: TRU-01, AIR-01, AIR-08. Tests: TC-AIUI-01..
// Implemented here: "Build a roadmap for a job or topic". The person pastes a job description (or names a topic);
// the DevPilot API asks Gemini and answers with a path made only of labs that exist, plus a few labs that do not
// exist yet. The result is saved with this person's own data. The app never calls Gemini itself.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/motion.dart';
import '../dashboard/dashboard_data.dart';
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
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _plan() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = _kind == 'job_description'
          ? 'Paste a job description first.'
          : 'Type a topic first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final raw = await ref
          .read(devPilotApiProvider)
          .roadmap(kind: _kind, text: text, level: _level);
      final controller = ref.read(userDataProvider);
      final saved =
          SavedRoadmap.fromApi(raw, source: _kind, now: controller.today);
      if (saved == null)
        throw const ApiProblem('The planner gave an answer we could not use.',
            recovery: 'Try again with a shorter or clearer request.');
      controller.saveRoadmap(saved);
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
    final saved = ref.watch(userDataProvider).data?.roadmap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          key: const Key('roadmap-planner'),
          child: Padding(
            padding: const EdgeInsets.all(BL.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome, color: BL.primary),
                  const SizedBox(width: BL.space2),
                  Text('Build a roadmap for a job or topic',
                      style: text.titleLarge),
                ]),
                const SizedBox(height: BL.space1),
                Text(
                    'Paste a job description and get a path of real labs to prepare for it. Written by Gemini, checked by DevPilot.',
                    style: text.bodySmall),
                const SizedBox(height: BL.space4),
                Wrap(
                    spacing: BL.space4,
                    runSpacing: BL.space3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SegmentedButton<String>(
                        key: const Key('planner-kind'),
                        segments: const [
                          ButtonSegment(
                              value: 'job_description',
                              label: Text('Job description')),
                          ButtonSegment(value: 'topic', label: Text('Topic')),
                        ],
                        selected: {_kind},
                        onSelectionChanged: _busy
                            ? null
                            : (s) => setState(() => _kind = s.first),
                      ),
                      SegmentedButton<String>(
                        key: const Key('planner-level'),
                        segments: const [
                          ButtonSegment(
                              value: 'beginner', label: Text('Beginner')),
                          ButtonSegment(
                              value: 'intermediate',
                              label: Text('Intermediate')),
                        ],
                        selected: {_level},
                        onSelectionChanged: _busy
                            ? null
                            : (s) => setState(() => _level = s.first),
                      ),
                    ]),
                const SizedBox(height: BL.space3),
                TextField(
                  key: const Key('planner-text'),
                  controller: _text,
                  enabled: !_busy,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 6000,
                  decoration: InputDecoration(
                    hintText: _kind == 'job_description'
                        ? 'Paste the job description here...'
                        : 'For example: backend development with Python and FastAPI',
                  ),
                ),
                const SizedBox(height: BL.space2),
                Row(children: [
                  FilledButton.icon(
                    key: const Key('planner-submit'),
                    onPressed: _busy ? null : _plan,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.route, size: 18),
                    label: Text(_busy
                        ? 'Planning (about 15 seconds)...'
                        : 'Plan my roadmap'),
                  ),
                  const SizedBox(width: BL.space3),
                  Expanded(
                      child: Text(
                          'Your text is sent to the DevPilot service with passwords and keys removed.',
                          style: text.bodySmall)),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: BL.space3),
                  Container(
                    key: const Key('planner-error'),
                    padding: const EdgeInsets.all(BL.space3),
                    decoration: BoxDecoration(
                        color: BL.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(BL.radiusMd)),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: BL.danger, size: 20),
                      const SizedBox(width: BL.space3),
                      Expanded(child: Text(_error!)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (saved != null) ...[
          const SizedBox(height: BL.space6),
          Reveal(
              key: ValueKey(saved.createdAt),
              child: _SavedRoadmapCard(roadmap: saved)),
        ],
      ],
    );
  }
}

class _SavedRoadmapCard extends ConsumerWidget {
  const _SavedRoadmapCard({required this.roadmap});

  final SavedRoadmap roadmap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final labSteps = roadmap.steps.where((s) => s.kind == 'lab').toList();
    final done = labSteps
        .where((s) => data?.statusOf(s.labId!) == LabStatus.practiceComplete)
        .length;
    return Card(
      key: const Key('saved-roadmap'),
      child: Padding(
        padding: const EdgeInsets.all(BL.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(roadmap.title, style: text.titleLarge)),
              StatusChip(
                  label: roadmap.source == 'topic'
                      ? 'From a topic'
                      : 'From a job description',
                  color: BL.navy),
              const SizedBox(width: BL.space2),
              IconButton(
                key: const Key('roadmap-clear'),
                tooltip: 'Remove this roadmap',
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(userDataProvider).clearRoadmap(),
              ),
            ]),
            const SizedBox(height: BL.space2),
            Text(
                labSteps.isEmpty
                    ? 'No ready-made lab matches yet.'
                    : '$done of ${labSteps.length} ready-made labs done',
                style: text.bodySmall),
            const SizedBox(height: BL.space4),
            for (var i = 0; i < roadmap.steps.length; i++)
              _StepRow(index: i, step: roadmap.steps[i], data: data),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.step, required this.data});

  final int index;
  final RoadmapStepData step;
  final UserData? data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLab = step.kind == 'lab';
    final activity = isLab ? SampleData.find(step.labId!) : null;
    final complete =
        isLab && data?.statusOf(step.labId!) == LabStatus.practiceComplete;
    return Container(
      key: Key('roadmap-step-$index'),
      margin: const EdgeInsets.only(bottom: BL.space2),
      padding: const EdgeInsets.all(BL.space3),
      decoration: BoxDecoration(
        color: isLab ? BL.selected : BL.surfaceMuted,
        borderRadius: BorderRadius.circular(BL.radiusMd),
        border: Border.all(color: BL.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              complete
                  ? Icons.check_circle
                  : (isLab ? Icons.radio_button_unchecked : Icons.schedule),
              color: complete ? BL.success : BL.textSecondary),
          const SizedBox(width: BL.space3),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${index + 1}. ${activity?.title ?? step.title}',
                  style: text.titleSmall),
              if (step.why.isNotEmpty) Text(step.why, style: text.bodySmall),
              if (step.skills.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: BL.space1),
                    child: Text(step.skills.join(' · '),
                        style: text.bodySmall?.copyWith(color: BL.primary))),
            ]),
          ),
          const SizedBox(width: BL.space3),
          if (isLab && activity != null)
            OutlinedButton(
                onPressed: () => context.go('/course/${step.labId}'),
                child: Text(actionFor(activity, data)))
          else
            const StatusChip(label: 'No lab yet', color: BL.textSecondary),
        ],
      ),
    );
  }
}
