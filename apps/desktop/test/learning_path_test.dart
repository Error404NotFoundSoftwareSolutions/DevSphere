// Capability: CAP-LEARNING-PATH. Tests: TC-LP-01..14
// Implemented here: a learning path is validated, saved with the right person, unlocks one step at a time, and a step
// is finished only when its videos (80%, measured), quick check (2 of 3) and lab are all done.
import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/data/user_data.dart';
import 'package:desktop/data/user_store.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/features/learn/video_player.dart';
import 'package:desktop/features/pages/roadmap_planner.dart' show inferKind;
import 'package:desktop/router.dart';
import 'package:desktop/services/devpilot_api.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/api_stub.dart';

const asha =
    AuthUser(uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha');

Map<String, dynamic> outline() => {
      'title': 'Git for beginners',
      'summary': 'For students new to Git.',
      'steps': [
        for (final s in ['branches', 'commits', 'merging'])
          {
            'id': s,
            'title': 'Learn $s',
            'objective': 'You can use $s.',
            'skills': ['Git'],
            'minutes': 40
          }
      ],
    };

Map<String, dynamic> stepDetail(
        {String lab = 'python-hello-001', bool videos = true}) =>
    {
      'intro_md':
          'A **branch** is a line of work.\n\n- Make one with `git switch -c`\n- Merge it back',
      'key_points': ['Branches are cheap', 'Switch often', 'Merge when done'],
      'videos': videos
          ? [
              {
                'video_id': 'abcdefghijk',
                'why': 'See a branch made',
                'title': 'Git branches',
                'channel': 'Teach',
                'duration_s': 600
              }
            ]
          : [],
      'videos_available': videos,
      'quiz': [
        for (var i = 0; i < 3; i++)
          {
            'question': 'Question $i?',
            'options': ['right $i', 'wrong a', 'wrong b'],
            'answer_index': 0,
            'explain': 'Because.'
          }
      ],
      'lab': {'kind': 'catalog', 'lab_id': lab, 'title': 'Hello, Python'},
    };

class PathApi extends DevPilotApiStub {
  final created = <Map<String, String>>[];
  final built = <String>[];
  bool failBuild = false;

  @override
  Future<Map<String, dynamic>> createPath(
      {required String goal,
      String level = 'beginner',
      String language = 'en'}) async {
    created.add({'goal': goal, 'level': level, 'language': language});
    return outline();
  }

  @override
  Future<Map<String, dynamic>> buildPathStep({
    required String goal,
    required String pathTitle,
    required Map<String, Object?> step,
    List<String> previous = const [],
    String level = 'beginner',
    String language = 'en',
  }) async {
    built.add('${step['id']}');
    if (failBuild)
      throw const ApiProblem('The step builder is not available right now.',
          recovery: 'Try again later.');
    return stepDetail();
  }
}

/// Stands in for the native player: buttons send what the real player page would send.
class FakeVideo extends StatelessWidget {
  const FakeVideo({super.key, required this.onMessage});
  final void Function(PlayerMessage) onMessage;
  @override
  Widget build(BuildContext context) => Row(children: [
        TextButton(
            key: const Key('fake-watch-90'),
            onPressed: () => onMessage(
                {'type': 'progress', 'watched': 540, 'duration': 600}),
            child: const Text('watch 90%')),
        TextButton(
            key: const Key('fake-watch-30'),
            onPressed: () => onMessage(
                {'type': 'progress', 'watched': 180, 'duration': 600}),
            child: const Text('watch 30%')),
        TextButton(
            key: const Key('fake-no-player'),
            onPressed: () => onMessage({'type': 'unavailable'}),
            child: const Text('no player')),
      ]);
}

Future<void> tapIn(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
}

Future<MemoryUserStore> pumpApp(WidgetTester tester, PathApi api,
    {String location = '/paths', MemoryUserStore? store}) async {
  final s = store ?? MemoryUserStore();
  AuthSession.instance.signOut();
  AuthSession.instance.signIn(asha);
  addTearDown(AuthSession.instance.signOut);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(MockWorkerClient()),
      userStoreProvider.overrideWithValue(s),
      devPilotApiProvider.overrideWithValue(api),
      videoViewBuilderProvider.overrideWithValue((
              {required Key key,
              required String videoId,
              required void Function(PlayerMessage) onMessage}) =>
          FakeVideo(key: key, onMessage: onMessage)),
    ],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
  return s;
}

StudyPath samplePath() => StudyPath.fromApi(outline(),
    id: 'p1700000000000',
    goal: 'git',
    level: 'beginner',
    language: 'en',
    now: DateTime(2026, 11, 11))!;

void main() {
  group('model', () {
    test(
        'TC-LP-01 the outline and step answers are validated; bad parts are dropped',
        () {
      final p = samplePath();
      expect(p.steps.map((s) => s.id), ['branches', 'commits', 'merging']);
      expect(
          StudyPath.fromApi({'title': 'x', 'steps': []},
              id: 'p1',
              goal: 'g',
              level: 'b',
              language: 'en',
              now: DateTime(2026)),
          isNull);
      expect(StepDetail.parse(stepDetail()), isNotNull);
      expect(StepDetail.parse({...stepDetail(), 'quiz': []}), isNull,
          reason: 'exactly three questions');
      expect(
          StepDetail.parse({
            ...stepDetail(),
            'lab': {'kind': 'catalog', 'lab_id': '../x'}
          }),
          isNull);
      final badVideo = StepDetail.parse({
        ...stepDetail(),
        'videos': [
          {'video_id': 'javascript:alert(1)'}
        ]
      })!;
      expect(badVideo.videos, isEmpty,
          reason: 'a video id must be a real 11-character id');
      final badAnswer = {...stepDetail()};
      badAnswer['quiz'] = [
        for (var i = 0; i < 3; i++)
          {
            'question': 'q',
            'options': ['a', 'b', 'c'],
            'answer_index': 7,
            'explain': ''
          }
      ];
      expect(StepDetail.parse(badAnswer), isNull);
    });

    test(
        'TC-LP-02 a step is complete only with video >= 80%, quick check >= 2 and the lab done',
        () {
      var p = samplePath();
      final detail = StepDetail.parse(stepDetail())!;
      bool labDone(String id) => id == 'python-hello-001';
      bool noLab(String id) => false;
      p = p.withStep(0, p.steps[0].copyWith(detail: detail));
      expect(p.stepComplete(0, labDone), isFalse);
      expect(p.unlocked(1, labDone), isFalse,
          reason: 'the next step stays locked');
      p = p.withStep(
          0, p.steps[0].copyWith(watched: {'abcdefghijk': 0.79}, quizBest: 3));
      expect(p.stepComplete(0, labDone), isFalse, reason: '79% is not enough');
      p = p.withStep(
          0, p.steps[0].copyWith(watched: {'abcdefghijk': 0.8}, quizBest: 1));
      expect(p.stepComplete(0, labDone), isFalse,
          reason: '1 of 3 is not enough');
      p = p.withStep(0, p.steps[0].copyWith(quizBest: 2));
      expect(p.stepComplete(0, noLab), isFalse, reason: 'the lab must be done');
      expect(p.stepComplete(0, labDone), isTrue);
      expect(p.unlocked(1, labDone), isTrue);
      expect(p.unlocked(2, labDone), isFalse);
      expect(p.currentIndex(labDone), 1);
    });

    test('TC-LP-03 paths are saved with the person and read back safely', () {
      final p = samplePath();
      final withProgress = p.withStep(
          0,
          p.steps[0].copyWith(
              detail: StepDetail.parse(stepDetail()),
              watched: {'abcdefghijk': 0.9},
              quizBest: 2));
      final d =
          const UserData(uid: 'u').copyWith(learningPaths: [withProgress]);
      final back = UserData.fromJson(d.toJson(), uid: 'u');
      final s0 = back.learningPaths.single.steps[0];
      expect(s0.watched['abcdefghijk'], 0.9);
      expect(s0.quizBest, 2);
      expect(s0.detail!.quiz.length, 3);
      final junk = UserData.fromJson({
        ...d.toJson(),
        'learningPaths': [
          {'id': '../../x', 'title': 'x'},
          'junk',
          withProgress.toJson(),
        ],
      }, uid: 'u');
      expect(junk.learningPaths.map((p) => p.id), ['p1700000000000']);
    });
  });

  testWidgets(
      'TC-LP-10 a goal becomes a path, the first step is prepared and the rest stay locked',
      (tester) async {
    final api = PathApi();
    final store = await pumpApp(tester, api);
    await tester.enterText(
        find.byKey(const Key('planner-text')), 'understand git branches');
    await tester.tap(find.byKey(const Key('path-create')));
    await tester.pumpAndSettle();
    expect(api.created.single['goal'], 'understand git branches');
    expect(find.byKey(const Key('learn-screen')), findsOneWidget);
    expect(find.text('Git for beginners'), findsOneWidget);
    expect(api.built, ['branches'], reason: 'only the first step is prepared');
    expect(find.text('Branches are cheap'), findsOneWidget);
    await tester.tap(find.byKey(const Key('learn-step-commits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('learn-locked')), findsOneWidget);
    expect(api.built, ['branches'], reason: 'a locked step is not prepared');
    final saved = await store.load('asha-uid');
    expect(saved.learningPaths.single.steps[0].detail, isNotNull,
        reason: 'kept with this person');
  });

  testWidgets(
      'TC-LP-11 watching to 80% (measured), passing the check and finishing the lab unlocks the next step',
      (tester) async {
    final api = PathApi();
    final store = MemoryUserStore();
    await store.save(const UserData(uid: 'asha-uid')
        .copyWith(learningPaths: [samplePath()]));
    await pumpApp(tester, api, location: '/learn/p1700000000000', store: store);

    // Watch: 30% is not enough, 90% is.
    await tester.tap(find.byKey(const Key('learn-tab-watch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-watch-30')));
    await tester.pumpAndSettle();
    expect(find.text('Watched 30% of 80% needed'), findsOneWidget);
    expect(find.byKey(const Key('learn-self-report')), findsNothing,
        reason: 'the player works, so no self-report');
    await tester.tap(find.byKey(const Key('fake-watch-90')));
    await tester.pumpAndSettle();
    expect(find.text('Watched'), findsOneWidget);

    // Quick check: one right is not enough, then all right.
    await tapIn(tester, const Key('learn-tab-quick-check'));
    await tester.pumpAndSettle();
    await tapIn(tester, const Key('quiz-q0-o0'));
    await tapIn(tester, const Key('quiz-q1-o1'));
    await tapIn(tester, const Key('quiz-q2-o1'));
    await tapIn(tester, const Key('quiz-check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 3 correct'), findsOneWidget);
    await tapIn(tester, const Key('quiz-retry'));
    await tester.pumpAndSettle();
    for (var q = 0; q < 3; q++) {
      await tapIn(tester, Key('quiz-q$q-o0'));
    }
    await tapIn(tester, const Key('quiz-check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 of 3 correct'), findsOneWidget);
    expect(find.byKey(const Key('learn-step-complete')), findsNothing,
        reason: 'the lab is not done yet');

    // The lab's checks pass (as the lab session would report them).
    final users = ProviderScope.containerOf(
            tester.element(find.byKey(const Key('learn-screen'))))
        .read(userDataProvider);
    users.recordLab(
        labId: 'python-hello-001',
        title: 'Hello',
        labRoot: '/x',
        steps: const [
          StepProgress(id: 'a', title: 'A', state: 'pass'),
        ]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('learn-step-complete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('learn-next')));
    await tester.pumpAndSettle();
    expect(api.built, ['branches', 'commits'],
        reason: 'each step is prepared when it opens');
    final saved = (await store.load('asha-uid')).learningPaths.single.steps[0];
    expect(saved.watched['abcdefghijk'], greaterThanOrEqualTo(0.8));
    expect(saved.quizBest, 3);
  });

  testWidgets(
      'TC-LP-12 when the player cannot run, the person can watch on YouTube and say so (labelled)',
      (tester) async {
    final store = MemoryUserStore();
    final p = samplePath();
    await store.save(const UserData(uid: 'asha-uid').copyWith(learningPaths: [
      p.withStep(0, p.steps[0].copyWith(detail: StepDetail.parse(stepDetail())))
    ]));
    await pumpApp(tester, PathApi(),
        location: '/learn/p1700000000000', store: store);
    await tester.tap(find.byKey(const Key('learn-tab-watch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-no-player')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('learn-self-report')));
    await tester.pumpAndSettle();
    expect(find.text('Marked as watched by you'), findsOneWidget);
  });

  testWidgets(
      'TC-LP-13 a step that cannot be prepared says why and can be retried',
      (tester) async {
    final api = PathApi()..failBuild = true;
    final store = MemoryUserStore();
    await store.save(const UserData(uid: 'asha-uid')
        .copyWith(learningPaths: [samplePath()]));
    await pumpApp(tester, api, location: '/learn/p1700000000000', store: store);
    expect(find.byKey(const Key('learn-build-error')), findsOneWidget);
    expect(find.textContaining('not available right now'), findsOneWidget);
    api.failBuild = false;
    await tester.tap(find.byKey(const Key('learn-build-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Branches are cheap'), findsOneWidget);
  });

  testWidgets('TC-LP-14 another person does not see my paths', (tester) async {
    final store = MemoryUserStore();
    await store.save(const UserData(uid: 'asha-uid')
        .copyWith(learningPaths: [samplePath()]));
    await pumpApp(tester, PathApi(), store: store);
    expect(find.byKey(const Key('my-path-p1700000000000')), findsOneWidget);
    AuthSession.instance.signOut();
    AuthSession.instance.signIn(const AuthUser(
        uid: 'bob-uid', email: 'bob@example.com', displayName: 'Bob'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-path-p1700000000000')), findsNothing);
  });

  testWidgets(
      'TC-LP-15 one card, one text box: paths, roadmaps and interview questions share it',
      (tester) async {
    final api = PathApi();
    await pumpApp(tester, api);
    expect(find.byKey(const Key('roadmap-planner')), findsOneWidget);
    expect(find.byKey(const Key('planner-text')), findsOneWidget,
        reason: 'a single text box');
    expect(find.byKey(const Key('path-create')), findsOneWidget);
    expect(find.byKey(const Key('planner-submit')), findsOneWidget);
    expect(find.byKey(const Key('planner-interview')), findsOneWidget);
    expect(find.text('Learn anything, step by step'), findsNothing,
        reason: 'the second card is gone');
    await tester.enterText(
        find.byKey(const Key('planner-text')), 'understand git branches');
    await tester.pump();
    expect(find.text('Treated as a topic or goal.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('planner-text')), 'Junior developer\nPython, Git');
    await tester.pump();
    expect(find.text('Treated as a job description.'), findsOneWidget);
  });

  test(
      'TC-LP-16 short single-line text is a topic; long or multi-line text is a job description',
      () {
    expect(inferKind('learn git'), 'topic');
    expect(inferKind('Backend developer\nPython'), 'job_description');
    expect(inferKind('x' * 241), 'job_description');
    expect(inferKind('  learn git  '), 'topic');
  });
}
