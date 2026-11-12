// Capability: CAP-LEARNING-PATH. Rules: TRU-01, AIR-01, AIR-08. Tests: TC-LP-10..
// Implemented here: one learning path, step by step. Steps unlock one at a time. When a step is opened for the first
// time the DevPilot API fills it in (explanation, real YouTube videos, quick check, lab). A step is finished when each
// video was watched to 80% (measured by the player in the app), the quick check was passed (2 of 3) and the lab's
// checks all passed in VS Code. The video lives in its own tab and never in a scrolling area, because the native
// player window reports what was really watched.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/fx.dart';
import '../../ui/kit.dart';
import '../../ui/simple_markdown.dart';
import '../../worker/worker_client.dart';
import 'video_player.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

enum _Tab { learn, watch, check, practice }

class _LearnScreenState extends ConsumerState<LearnScreen> {
  int? _selected;
  _Tab _tab = _Tab.learn;
  final Set<int> _building = {};
  final Map<int, String> _buildErrors = {};

  // Watch
  int _video = 0;
  final Map<String, double> _live =
      {}; // fraction seen this session, updated every second
  final Set<String> _noPlayer = {}; // videos the player could not play here

  // Quick check
  final Map<int, int> _answers = {};
  bool _checked = false;

  // Practice
  bool _labBusy = false;
  String? _labError;

  bool Function(String) _labDone(UserData d) => d.labDone;

  void _select(int i) {
    setState(() {
      _selected = i;
      _tab = _Tab.learn;
      _video = 0;
      _answers.clear();
      _checked = false;
      _labError = null;
    });
  }

  Future<void> _build(StudyPath p, int i) async {
    if (_building.contains(i)) return;
    setState(() {
      _building.add(i);
      _buildErrors.remove(i);
    });
    final s = p.steps[i];
    try {
      final raw = await ref.read(devPilotApiProvider).buildPathStep(
            goal: p.goal,
            pathTitle: p.title,
            step: {
              'id': s.id,
              'title': s.title,
              'objective': s.objective,
              'skills': s.skills
            },
            previous: [for (var k = 0; k < i; k++) p.steps[k].title],
            level: p.level,
            language: p.language,
          );
      final detail = StepDetail.parse(raw);
      if (detail == null) {
        throw const ApiProblem(
            'The step came back in a shape DevPilot cannot use.',
            recovery: 'Try again.');
      }
      ref
          .read(userDataProvider)
          .updatePathStep(p.id, i, s.copyWith(detail: detail));
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _buildErrors[i] = e.toString());
    } catch (_) {
      if (mounted)
        setState(() =>
            _buildErrors[i] = 'This step could not be prepared. Try again.');
    } finally {
      if (mounted) setState(() => _building.remove(i));
    }
  }

  void _onPlayer(StudyPath p, int i, PathVideo v, PlayerMessage m) {
    final type = m['type'];
    if (type == 'unavailable' || type == 'error') {
      if (mounted && !_noPlayer.contains(v.videoId))
        setState(() => _noPlayer.add(v.videoId));
      return;
    }
    if (type != 'progress') return;
    final watched = m['watched'], duration = m['duration'];
    if (watched is! num || duration is! num || duration <= 0) return;
    final frac = (watched / duration).clamp(0.0, 1.0).toDouble();
    if (frac <= (_live[v.videoId] ?? 0)) return;
    if (mounted) setState(() => _live[v.videoId] = frac);
    // Save now and then, and always when the goal is reached.
    final step = ref.read(userDataProvider).data?.path(p.id)?.steps[i];
    if (step == null) return;
    final saved = step.watched[v.videoId] ?? 0;
    final crossed = saved < videoGoal && frac >= videoGoal;
    if (crossed || frac - saved >= 0.05 || m['ended'] == true) {
      ref.read(userDataProvider).updatePathStep(
          p.id, i, step.copyWith(watched: {...step.watched, v.videoId: frac}));
    }
  }

  void _selfReport(StudyPath p, int i, PathVideo v) {
    final step = p.steps[i];
    ref.read(userDataProvider).updatePathStep(p.id, i,
        step.copyWith(selfReported: {...step.selfReported, v.videoId}));
  }

  void _checkQuiz(StudyPath p, int i) {
    final step = p.steps[i];
    final quiz = step.detail!.quiz;
    var score = 0;
    for (var q = 0; q < quiz.length; q++) {
      if (_answers[q] == quiz[q].answerIndex) score++;
    }
    setState(() => _checked = true);
    if (score > step.quizBest) {
      ref
          .read(userDataProvider)
          .updatePathStep(p.id, i, step.copyWith(quizBest: score));
    }
  }

  Future<void> _createLab(StudyPath p, int i) async {
    final step = p.steps[i];
    final topic = step.detail?.labTopic;
    if (topic == null || _labBusy) return;
    setState(() {
      _labBusy = true;
      _labError = null;
    });
    try {
      final r = await ref
          .read(devPilotApiProvider)
          .generateLab(topic: topic, level: p.level);
      final lab = r['lab'];
      if (r['status'] != 'verified' || lab is! Map<String, dynamic>) {
        throw const ApiProblem(
            'The lab did not pass its own checks, so it was not added.',
            recovery: 'Try again.');
      }
      if (!mounted) return;
      final agreed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Add this AI-written lab?'),
          content: Text(
            '"${lab['title']}". Gemini wrote it and DevPilot proved it works (the reference passes and every step '
            'fails on the starter), but no person has reviewed it. Its tests run Python code on your computer '
            'when you press "Check my work".',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                key: const Key('learn-lab-agree'),
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Add the lab')),
          ],
        ),
      );
      if (agreed != true) return;
      final w = await ref
          .read(workerClientProvider)
          .send('labforge:install', {'lab': lab});
      if (w['ok'] != true || w['labId'] is! String) {
        throw ApiProblem('${w['message'] ?? 'The lab could not be added.'}',
            recovery: 'Try again.');
      }
      final id = w['labId'] as String;
      final users = ref.read(userDataProvider);
      users.addGeneratedLab(GeneratedLabRef(
          labId: id,
          title: '${w['title'] ?? lab['title']}',
          topic: topic,
          createdAt: users.today.toIso8601String()));
      final fresh = users.data?.path(p.id)?.steps[i] ?? step;
      users.updatePathStep(p.id, i, fresh.copyWith(installedLabId: id));
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _labError = e.toString());
    } on WorkerException catch (e) {
      if (mounted) setState(() => _labError = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _labError = 'The lab could not be created. Try again.');
    } finally {
      if (mounted) setState(() => _labBusy = false);
    }
  }

  // ------------------------------------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(userDataProvider).data;
    final p = data?.path(widget.id);
    final text = Theme.of(context).textTheme;
    if (data == null || p == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('This learning path is not here.', style: text.titleMedium),
          const SizedBox(height: BL.space3),
          FilledButton(
              onPressed: () => context.go('/paths'),
              child: const Text('Back to Paths')),
        ]),
      );
    }
    final done = _labDone(data);
    final current = p.currentIndex(done);
    // Remember the step on screen, so finishing it shows the celebration instead of jumping away.
    _selected ??= current < 0 ? p.steps.length - 1 : current;
    final selected = _selected!.clamp(0, p.steps.length - 1);
    final completed = p.completedCount(done);

    // Fill in the selected step the first time it is opened.
    final s = p.steps[selected];
    if (s.detail == null &&
        p.unlocked(selected, done) &&
        !_building.contains(selected) &&
        !_buildErrors.containsKey(selected)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _build(p, selected);
      });
    }

    return Column(
      key: const Key('learn-screen'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
              BL.space6, BL.space4, BL.space6, BL.space4),
          decoration: BoxDecoration(
              color: BL.surface,
              border: Border(bottom: BorderSide(color: BL.border))),
          child: Row(children: [
            IconButton(
                tooltip: 'Back to Paths',
                onPressed: () => context.go('/paths'),
                icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: BL.space2),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        key: const Key('learn-title'),
                        style: text.headlineSmall),
                    if (p.summary.isNotEmpty)
                      Text(p.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall),
                  ]),
            ),
            const SizedBox(width: BL.space6),
            SizedBox(
              width: 220,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                    current < 0
                        ? 'Path complete'
                        : '$completed of ${p.steps.length} steps done',
                    key: const Key('learn-progress'),
                    style: text.titleSmall
                        ?.copyWith(color: current < 0 ? BL.success : null)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: completed / p.steps.length,
                      minHeight: 6,
                      color: current < 0 ? BL.success : BL.primary),
                ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 300,
              decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: BL.border))),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    BL.space2, BL.space3, BL.space2, BL.space6),
                child: _Journey(
                    path: p,
                    selected: selected,
                    labDone: done,
                    onSelect: _select),
              ),
            ),
            Expanded(child: _stepPanel(context, p, selected, done)),
          ]),
        ),
      ],
    );
  }

  Widget _stepPanel(
      BuildContext context, StudyPath p, int i, bool Function(String) done) {
    final text = Theme.of(context).textTheme;
    final s = p.steps[i];
    if (!p.unlocked(i, done)) {
      return Center(
        key: const Key('learn-locked'),
        child: Padding(
          padding: const EdgeInsets.all(BL.space8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline, size: 40, color: BL.textDisabled),
            const SizedBox(height: BL.space3),
            Text('This step opens when the step before it is finished.',
                style: text.titleMedium),
            const SizedBox(height: BL.space2),
            Text('Finish its video, quick check and lab first.',
                style: text.bodySmall),
          ]),
        ),
      );
    }
    final d = s.detail;
    if (d == null) {
      final err = _buildErrors[i];
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BL.space8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (err == null) ...[
              const SizedBox(
                  width: 420,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(height: 22, width: 260),
                        SizedBox(height: 12),
                        ShimmerBox(height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(height: 14, width: 320),
                        SizedBox(height: 20),
                        Row(children: [
                          ShimmerBox(height: 90, width: 200, radius: 12),
                          SizedBox(width: 12),
                          ShimmerBox(height: 90, width: 200, radius: 12)
                        ]),
                      ])),
              const SizedBox(height: BL.space4),
              Text('Preparing "${s.title}"',
                  key: const Key('learn-building'), style: text.titleMedium),
              const SizedBox(height: BL.space2),
              Text(
                  'Writing the explanation, finding videos and making the quick check. This takes a few seconds.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall),
            ] else ...[
              Text(err,
                  key: const Key('learn-build-error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BL.danger)),
              const SizedBox(height: BL.space3),
              FilledButton(
                  key: const Key('learn-build-retry'),
                  onPressed: () {
                    setState(() => _buildErrors.remove(i));
                    _build(p, i);
                  },
                  child: const Text('Try again')),
            ],
          ]),
        ),
      );
    }

    final lab = s.labId;
    final labOk = lab != null && done(lab);
    final complete = p.stepComplete(i, done);
    Widget chip(String label, bool ok, Key key) => Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ok ? BL.success.withValues(alpha: 0.12) : BL.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 15, color: ok ? BL.success : BL.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    color: ok ? BL.success : BL.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        );

    final tabs = const ['Learn', 'Watch', 'Quick check', 'Practice'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(BL.space6, BL.space4, BL.space6, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (complete)
          Stack(clipBehavior: Clip.none, children: [
            Container(
              key: const Key('learn-step-complete'),
              margin: const EdgeInsets.only(bottom: BL.space3),
              padding: const EdgeInsets.all(BL.space3),
              decoration: BoxDecoration(
                  color: BL.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BL.radiusMd),
                  border: Border.all(color: BL.success.withValues(alpha: 0.4))),
              child: Row(children: [
                Icon(Icons.celebration_outlined, color: BL.success),
                const SizedBox(width: BL.space3),
                Expanded(
                  child: Text(
                      i == p.steps.length - 1
                          ? 'You finished the whole path. Well done!'
                          : 'Step complete. The next step is open.',
                      style: text.titleSmall),
                ),
                if (i < p.steps.length - 1)
                  FilledButton(
                      key: const Key('learn-next'),
                      onPressed: () => _select(i + 1),
                      child: const Text('Next step')),
              ]),
            ),
            const Positioned.fill(child: Confetti()),
          ]),
        Text(s.title, style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(s.objective, style: text.bodySmall),
        const SizedBox(height: BL.space3),
        Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
          chip(d.videos.isEmpty ? 'No video for this step' : 'Videos watched',
              s.videosDone, const Key('cp-video')),
          chip('Quick check ${s.quizBest < 0 ? '' : '${s.quizBest}/3'}',
              s.quizDone, const Key('cp-quiz')),
          chip('Lab checks', labOk, const Key('cp-lab')),
        ]),
        const SizedBox(height: BL.space3),
        Align(
          alignment: Alignment.centerLeft,
          child: PillTabs(
            labels: tabs,
            selected: _tab.index,
            itemKey: (l) =>
                Key('learn-tab-${l.toLowerCase().replaceAll(' ', '-')}'),
            onChanged: (t) => setState(() => _tab = _Tab.values[t]),
          ),
        ),
        const SizedBox(height: BL.space3),
        Expanded(
          child: switch (_tab) {
            _Tab.learn => _learnTab(context, d),
            _Tab.watch => _watchTab(context, p, i, d),
            _Tab.check => _checkTab(context, p, i, d),
            _Tab.practice => _practiceTab(context, p, i, d, labOk),
          },
        ),
      ]),
    );
  }

  Widget _learnTab(BuildContext context, StepDetail d) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      key: const Key('learn-tab-body-learn'),
      padding: const EdgeInsets.only(bottom: BL.space8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SimpleMarkdown(d.introMd),
        if (d.keyPoints.isNotEmpty) ...[
          const SizedBox(height: BL.space3),
          Text('KEY POINTS',
              style: BL.mono(size: 11, color: BL.textSecondary, spacing: 0.6)),
          const SizedBox(height: BL.space2),
          for (final k in d.keyPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check, size: 16, color: BL.primary),
                const SizedBox(width: BL.space2),
                Expanded(child: Text(k, style: text.bodyMedium)),
              ]),
            ),
        ],
        const SizedBox(height: BL.space4),
        FilledButton.icon(
          onPressed: () => setState(() => _tab = _Tab.watch),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Next: watch'),
        ),
      ]),
    );
  }

  Widget _watchTab(BuildContext context, StudyPath p, int i, StepDetail d) {
    final text = Theme.of(context).textTheme;
    if (d.videos.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          d.videosAvailable
              ? 'No video fits this step well, so there is nothing to watch. It counts as done.'
              : 'Videos are not available right now (the video search is not set up), so this step needs no video.',
          key: const Key('learn-no-videos'),
          style: text.bodyMedium,
        ),
      );
    }
    final s = p.steps[i];
    final v = d.videos[_video.clamp(0, d.videos.length - 1)];
    final frac = [_live[v.videoId] ?? 0, s.watched[v.videoId] ?? 0]
        .reduce((a, b) => a > b ? a : b);
    final ok = s.videoDone(v.videoId);
    final noPlayer = _noPlayer.contains(v.videoId);
    final builder = ref.watch(videoViewBuilderProvider);
    final mins = (v.durationS / 60).round();
    // Nothing here scrolls: the native player must stay where Flutter put it.
    return Column(
        key: const Key('learn-tab-body-watch'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.videos.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: BL.space2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PillTabs(
                  labels: [
                    for (var k = 0; k < d.videos.length; k++)
                      'Video ${k + 1}${s.videoDone(d.videos[k].videoId) ? '  ✓' : ''}'
                  ],
                  selected: _video.clamp(0, d.videos.length - 1),
                  itemKey: (l) =>
                      Key('learn-video-${l.startsWith('Video 2') ? 1 : 0}'),
                  onChanged: (k) => setState(() => _video = k),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BL.radiusMd),
                  child: builder(
                    key: ValueKey('player-${v.videoId}'),
                    videoId: v.videoId,
                    onMessage: (m) => _onPlayer(p, i, v, m),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: BL.space3),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall),
                    Text(
                        '${v.channel}  ·  $mins min${v.why.isEmpty ? '' : '  ·  ${v.why}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall),
                  ]),
            ),
            const SizedBox(width: BL.space3),
            OutlinedButton.icon(
              key: const Key('learn-open-youtube'),
              onPressed: () => launchUrl(
                  Uri.parse('https://www.youtube.com/watch?v=${v.videoId}'),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('YouTube'),
            ),
            if (noPlayer && !ok) ...[
              const SizedBox(width: BL.space2),
              FilledButton(
                  key: const Key('learn-self-report'),
                  onPressed: () => _selfReport(p, i, v),
                  child: const Text('I watched it')),
            ],
          ]),
          const SizedBox(height: BL.space2),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    key: const Key('learn-watch-bar'),
                    value: ok ? 1 : frac,
                    minHeight: 6,
                    color: ok ? BL.success : BL.primary),
              ),
            ),
            const SizedBox(width: BL.space3),
            Text(
              ok
                  ? (s.selfReported.contains(v.videoId)
                      ? 'Marked as watched by you'
                      : 'Watched')
                  : 'Watched ${(frac * 100).round()}% of 80% needed',
              key: const Key('learn-watch-status'),
              style:
                  BL.mono(size: 12, color: ok ? BL.success : BL.textSecondary),
            ),
          ]),
          if (noPlayer && !ok)
            Padding(
              padding: const EdgeInsets.only(top: BL.space2),
              child: Text(
                  'The player cannot run on this computer. Watch on YouTube, then press "I watched it".',
                  style: TextStyle(color: BL.warning, fontSize: 12.5)),
            ),
          const SizedBox(height: BL.space4),
        ]);
  }

  Widget _checkTab(BuildContext context, StudyPath p, int i, StepDetail d) {
    final text = Theme.of(context).textTheme;
    final s = p.steps[i];
    var score = 0;
    for (var q = 0; q < d.quiz.length; q++) {
      if (_answers[q] == d.quiz[q].answerIndex) score++;
    }
    return SingleChildScrollView(
      key: const Key('learn-tab-body-check'),
      padding: const EdgeInsets.only(bottom: BL.space8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            'Answer at least 2 of 3 correctly. You can try as often as you like.',
            style: text.bodySmall),
        const SizedBox(height: BL.space3),
        for (var q = 0; q < d.quiz.length; q++)
          Container(
            key: Key('quiz-q$q'),
            margin: const EdgeInsets.only(bottom: BL.space3),
            padding: const EdgeInsets.all(BL.space4),
            decoration: BoxDecoration(
                color: BL.surface,
                borderRadius: BorderRadius.circular(BL.radiusLg),
                border: Border.all(color: BL.border)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${q + 1}. ${d.quiz[q].question}', style: text.titleSmall),
              const SizedBox(height: BL.space2),
              for (var o = 0; o < d.quiz[q].options.length; o++)
                InkWell(
                  key: Key('quiz-q$q-o$o'),
                  onTap:
                      _checked ? null : () => setState(() => _answers[q] = o),
                  borderRadius: BorderRadius.circular(BL.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(
                        _checked && o == d.quiz[q].answerIndex
                            ? Icons.check_circle
                            : _answers[q] == o
                                ? (_checked
                                    ? Icons.cancel
                                    : Icons.radio_button_checked)
                                : Icons.radio_button_unchecked,
                        size: 18,
                        color: _checked && o == d.quiz[q].answerIndex
                            ? BL.success
                            : (_checked && _answers[q] == o
                                ? BL.danger
                                : BL.primary),
                      ),
                      const SizedBox(width: BL.space2),
                      Expanded(
                          child: Text(d.quiz[q].options[o],
                              style: text.bodyMedium)),
                    ]),
                  ),
                ),
              if (_checked && d.quiz[q].explain.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: BL.space2),
                  child: Text(d.quiz[q].explain, style: text.bodySmall),
                ),
            ]),
          ),
        Row(children: [
          if (!_checked)
            FilledButton(
              key: const Key('quiz-check'),
              onPressed: _answers.length == d.quiz.length
                  ? () => _checkQuiz(p, i)
                  : null,
              child: const Text('Check my answers'),
            )
          else ...[
            Text(
                '$score of ${d.quiz.length} correct. ${score >= quizPassMark ? 'Passed.' : 'Not yet: 2 needed.'}',
                key: const Key('quiz-result'),
                style: text.titleSmall?.copyWith(
                    color: score >= quizPassMark ? BL.success : BL.danger)),
            const SizedBox(width: BL.space3),
            OutlinedButton(
                key: const Key('quiz-retry'),
                onPressed: () => setState(() {
                      _answers.clear();
                      _checked = false;
                    }),
                child: const Text('Try again')),
            if (s.quizDone || score >= quizPassMark) ...[
              const SizedBox(width: BL.space2),
              FilledButton(
                  onPressed: () => setState(() => _tab = _Tab.practice),
                  child: const Text('Next: practise')),
            ],
          ],
        ]),
      ]),
    );
  }

  Widget _practiceTab(
      BuildContext context, StudyPath p, int i, StepDetail d, bool labOk) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(userDataProvider).data;
    final s = p.steps[i];
    final labId = s.labId;
    final progress = labId == null ? null : data?.lab(labId);
    final title = d.labKind == 'catalog'
        ? (d.labTitle.isEmpty ? d.labId! : d.labTitle)
        : (d.labTopic ?? '');
    return SingleChildScrollView(
      key: const Key('learn-tab-body-practice'),
      padding: const EdgeInsets.only(bottom: BL.space8),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconTile(
                icon: Icons.terminal,
                tint: BL.tintBlue,
                color: BL.blue,
                size: 40),
            const SizedBox(width: BL.space3),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        d.labKind == 'catalog'
                            ? 'Lab from the catalogue'
                            : 'A lab written for this step',
                        style: BL.mono(size: 11, color: BL.textSecondary)),
                    Text(title, style: text.titleMedium),
                  ]),
            ),
            if (labOk)
              const Tag('All checks passed', tone: Tone.accent)
            else if (progress != null)
              Tag('${progress.passed} of ${progress.total} checks',
                  tone: Tone.info),
          ]),
          const SizedBox(height: BL.space3),
          Text(
            'The lab opens in VS Code with the DevPilot Guide. Press "Check my work" after each step; when every check '
            'passes, this part of the step is done.',
            style: text.bodySmall,
          ),
          const SizedBox(height: BL.space4),
          if (labId != null)
            FilledButton.icon(
              key: const Key('learn-open-lab'),
              onPressed: () => context.go('/course/$labId'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(labOk ? 'Open the lab again' : 'Open the lab'),
            )
          else ...[
            Text(
                'DevPilot will write this lab for you and prove it works before you see it. It takes about a minute.',
                style: text.bodySmall),
            const SizedBox(height: BL.space3),
            FilledButton.icon(
              key: const Key('learn-create-lab'),
              onPressed: _labBusy ? null : () => _createLab(p, i),
              icon: _labBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_labBusy
                  ? 'Writing and checking the lab...'
                  : 'Create this lab'),
            ),
          ],
          if (_labError != null)
            Padding(
              padding: const EdgeInsets.only(top: BL.space3),
              child: Text(_labError!,
                  key: const Key('learn-lab-error'),
                  style: TextStyle(color: BL.danger)),
            ),
        ]),
      ),
    );
  }
}

/// The steps as a winding road: nodes on a curve, a pulsing marker on the current step, locked steps greyed out.
class _Journey extends StatelessWidget {
  const _Journey(
      {required this.path,
      required this.selected,
      required this.labDone,
      required this.onSelect});

  final StudyPath path;
  final int selected;
  final bool Function(String) labDone;
  final void Function(int) onSelect;

  static const rowH = 108.0;
  static const nodeD = 46.0;

  double _x(int i) => 58 + 20 * math.sin(i * 1.25);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = path.steps.length;
    final current = path.currentIndex(labDone);
    final complete = [
      for (var i = 0; i < n; i++) path.stepComplete(i, labDone)
    ];
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return SizedBox(
        width: w,
        height: n * rowH,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _RoadPainter(n: n, x: _x, rowH: rowH, complete: complete)),
          ),
          for (var i = 0; i < n; i++)
            Positioned(
              left: _x(i) - nodeD / 2 - 10,
              top: i * rowH + 8,
              width: w - (_x(i) - nodeD / 2 - 10) - 4,
              height: rowH - 16,
              child: InkWell(
                key: Key('learn-step-${path.steps[i].id}'),
                borderRadius: BorderRadius.circular(BL.radiusMd),
                onTap: () => onSelect(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: i == selected
                        ? BL.selected.withValues(alpha: 0.7)
                        : null,
                    borderRadius: BorderRadius.circular(BL.radiusMd),
                  ),
                  padding: const EdgeInsets.only(left: 10, right: 8),
                  child: Row(children: [
                    _node(i, complete[i], i == current,
                        path.unlocked(i, labDone)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'STEP ${i + 1}  ·  ${path.steps[i].minutes} MIN',
                                style: BL.mono(
                                    size: 10.5,
                                    color: BL.textSecondary,
                                    spacing: 0.6)),
                            const SizedBox(height: 2),
                            Text(path.steps[i].title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall?.copyWith(
                                    color: path.unlocked(i, labDone)
                                        ? BL.textPrimary
                                        : BL.textDisabled,
                                    height: 1.25)),
                          ]),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      );
    });
  }

  Widget _node(int i, bool done, bool isCurrent, bool open) {
    final Widget core = Container(
      width: nodeD,
      height: nodeD,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: done
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BL.success, BL.teal])
            : open
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BL.blue, BL.violet])
                : null,
        color: open || done ? null : BL.surfaceMuted,
        border: Border.all(
            color: open || done
                ? Colors.white.withValues(alpha: 0.9)
                : BL.borderStrong,
            width: 2.5),
        boxShadow: open || done
            ? [
                BoxShadow(
                    color: (done ? BL.success : BL.blue).withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]
            : null,
      ),
      child: Icon(
        done
            ? Icons.check_rounded
            : (open ? Icons.play_arrow_rounded : Icons.lock_outline),
        color: open || done ? Colors.white : BL.textDisabled,
        size: done || open ? 26 : 20,
      ),
    );
    if (!isCurrent) return SizedBox(width: nodeD, child: core);
    return SizedBox(
      width: nodeD,
      height: nodeD,
      child: OverflowBox(
        maxWidth: nodeD * 1.9,
        maxHeight: nodeD * 1.9,
        child: PulseRing(color: BL.blue, size: nodeD, child: core),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(
      {required this.n,
      required this.x,
      required this.rowH,
      required this.complete});
  final int n;
  final double Function(int) x;
  final double rowH;
  final List<bool> complete;

  @override
  void paint(Canvas canvas, Size size) {
    Offset c(int i) => Offset(x(i), i * rowH + rowH / 2);
    for (var i = 0; i < n - 1; i++) {
      final a = c(i), b = c(i + 1);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(
            a.dx, a.dy + rowH * 0.55, b.dx, b.dy - rowH * 0.55, b.dx, b.dy);
      final done = complete[i];
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 7
          ..color = done ? BL.success.withValues(alpha: 0.9) : BL.border,
      );
      if (!done) {
        final metric = path.computeMetrics().first;
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2
          ..color = BL.surface;
        for (var d = 6.0; d < metric.length; d += 14) {
          canvas.drawPath(metric.extractPath(d, d + 6), dash);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.complete != complete || old.n != n;
}
