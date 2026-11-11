// Capability: CAP-ROADMAP, CAP-AI-CLIENT. Tests: TC-AIUI-01..08
// Implemented here: the roadmap planner and the tutor work through the API, keep results with the right person,
// and show failures plainly.
import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/data/user_data.dart';
import 'package:desktop/data/user_store.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/router.dart';
import 'package:desktop/services/devpilot_api.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const asha =
    AuthUser(uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha');
const bob =
    AuthUser(uid: 'bob-uid', email: 'bob@example.com', displayName: 'Bob');

class FakeApi implements DevPilotApi {
  FakeApi({this.roadmapError, this.askError, this.interviewError});
  final ApiProblem? interviewError;
  final ApiProblem? roadmapError;
  final ApiProblem? askError;
  final calls = <String>[];
  Map<String, dynamic>? lastRoadmapRequest;
  String? lastLanguage;

  @override
  Future<Map<String, dynamic>> roadmap(
      {required String kind,
      required String text,
      String level = 'beginner'}) async {
    calls.add('roadmap');
    lastRoadmapRequest = {'kind': kind, 'text': text, 'level': level};
    if (roadmapError != null) throw roadmapError!;
    return {
      'title': 'Backend intern path',
      'steps': [
        {
          'kind': 'lab',
          'lab_id': 'python-hello-001',
          'title': 'Hello, Python',
          'why': 'Learn the basics.',
          'skills': ['Python']
        },
        {
          'kind': 'lab',
          'lab_id': 'oss-first-contribution-001',
          'title': 'OSS',
          'why': 'Work like a team.',
          'skills': ['Git']
        },
        {
          'kind': 'generate',
          'lab_id': null,
          'title': 'REST APIs with FastAPI',
          'why': 'The job asks for APIs.',
          'skills': ['FastAPI']
        },
      ],
    };
  }

  Map<String, dynamic>? lastInterviewRequest;

  @override
  Future<Map<String, dynamic>> interview(
      {required String kind,
      required String text,
      String level = 'beginner'}) async {
    calls.add('interview');
    lastInterviewRequest = {'kind': kind, 'text': text, 'level': level};
    if (interviewError != null) throw interviewError!;
    return {
      'title': 'Backend intern interview',
      'questions': [
        {
          'kind': 'concept',
          'question': 'What is a branch in Git?',
          'hint': 'Think about parallel work.',
          'good_answer_covers': ['isolation', 'merging'],
          'skills': ['git']
        },
        {
          'kind': 'practical',
          'question': 'How do you resolve a merge conflict?',
          'hint': 'Look at the markers.',
          'good_answer_covers': ['markers'],
          'skills': ['git']
        },
        {
          'kind': 'behavioural',
          'question': 'Tell me about feedback you received.',
          'hint': 'Be specific.',
          'good_answer_covers': [],
          'skills': []
        },
        {
          'kind': 'concept',
          'question': 'What does pytest do?',
          'hint': '',
          'good_answer_covers': ['runs tests'],
          'skills': ['pytest']
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> generateLab({required String topic, String level = 'beginner'}) async => throw UnimplementedError();

  @override
  Future<String> attemptFor(String labId) async {
    calls.add('attempt:$labId');
    return 'att-1';
  }

  @override
  Future<TutorAnswer> ask(
      {required String attemptId,
      required String question,
      String language = 'en',
      String? code}) async {
    calls.add('ask');
    lastLanguage = language;
    if (askError != null) throw askError!;
    return const TutorAnswer(
        answer: 'Think about what index the last item has.', level: 3);
  }
}

Future<void> pump(
    WidgetTester tester, String location, MemoryUserStore store, FakeApi api,
    {AuthUser? user = asha}) async {
  AuthSession.instance.signOut();
  if (user != null) AuthSession.instance.signIn(user);
  addTearDown(AuthSession.instance.signOut);
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(MockWorkerClient()),
      userStoreProvider.overrideWithValue(store),
      devPilotApiProvider.overrideWithValue(api),
    ],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-AIUI-01 pasting a job description builds a roadmap with real labs and labs that do not exist yet',
      (tester) async {
    final api = FakeApi();
    await pump(tester, '/paths', MemoryUserStore(), api);
    expect(find.byKey(const Key('saved-roadmap')), findsNothing);
    await tester.enterText(find.byKey(const Key('planner-text')),
        'Junior backend developer. Python, Git, FastAPI.');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(api.lastRoadmapRequest, {
      'kind': 'job_description',
      'text': 'Junior backend developer. Python, Git, FastAPI.',
      'level': 'beginner'
    });
    expect(find.byKey(const Key('saved-roadmap')), findsOneWidget);
    expect(find.text('Backend intern path'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('roadmap-step-0')),
            matching: find.text('Open')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('roadmap-step-2')),
            matching: find.text('No lab yet')),
        findsOneWidget);
    expect(find.byKey(const Key('planner-error')), findsNothing);
  });

  testWidgets(
      'TC-AIUI-02 the roadmap is saved for this person only and survives a restart',
      (tester) async {
    final store = MemoryUserStore();
    await pump(tester, '/paths', store, FakeApi());
    await tester.enterText(find.byKey(const Key('planner-text')), 'anything');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect((await store.load('asha-uid')).roadmap!.steps.length, 3);
    expect((await store.load('bob-uid')).roadmap, isNull);
    await pump(tester, '/paths', store, FakeApi(), user: asha);
    expect(find.byKey(const Key('saved-roadmap')), findsOneWidget,
        reason: 'comes back from the saved data');
    await pump(tester, '/paths', store, FakeApi(), user: bob);
    expect(find.byKey(const Key('saved-roadmap')), findsNothing,
        reason: 'the next person does not see it');
  });

  testWidgets(
      'TC-AIUI-03 empty input, a service problem and removing a roadmap all behave',
      (tester) async {
    final api = FakeApi(
        roadmapError: const ApiProblem(
            'The planner is not available right now.',
            recovery: 'You can keep working; try again later.'));
    await pump(tester, '/paths', MemoryUserStore(), api);
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Paste a job description first'), findsOneWidget);
    expect(api.calls, isEmpty, reason: 'nothing is sent for empty input');
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const Key('planner-error')),
            matching: find.textContaining('try again later')),
        findsOneWidget);

    final ok = FakeApi();
    await pump(tester, '/paths', MemoryUserStore(), ok);
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roadmap-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved-roadmap')), findsNothing);
  });

  testWidgets(
      'TC-AIUI-04 a malformed answer from the service is rejected, not half shown',
      (tester) async {
    expect(
        SavedRoadmap.fromApi({'title': 'x', 'steps': 'nope'},
            source: 'topic', now: DateTime(2026)),
        isNull);
    expect(
        SavedRoadmap.fromApi({
          'title': 'x',
          'steps': [
            {'kind': 'lab', 'lab_id': '../../x', 'title': 't', 'why': 'w'}
          ]
        }, source: 'topic', now: DateTime(2026)),
        isNull,
        reason: 'a lab step needs a valid lab id');
    final r = SavedRoadmap.fromApi({
      'title': 'x',
      'steps': [
        {'kind': 'root-shell', 'title': 'bad'},
        {
          'kind': 'generate',
          'lab_id': null,
          'title': 'ok',
          'why': 'w',
          'skills': List.filled(20, 's')
        },
      ],
    }, source: 'topic', now: DateTime(2026))!;
    expect(r.steps.length, 1);
    expect(r.steps.single.skills.length, 6);
  });

  testWidgets(
      'TC-AIUI-05 the tutor sends the question in the chosen language and shows the answer',
      (tester) async {
    final api = FakeApi();
    await pump(tester, '/lab/python-hello-001', MemoryUserStore(), api);
    await tester.ensureVisible(find.byKey(const Key('tutor-panel')));
    await tester.tap(find.byKey(const Key('tutor-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ಕನ್ನಡ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('tutor-input')), 'Why IndexError?');
    await tester.tap(find.byKey(const Key('tutor-send')));
    await tester.pumpAndSettle();
    expect(api.calls, ['attempt:python-hello-001', 'ask']);
    expect(api.lastLanguage, 'kn');
    expect(find.text('Why IndexError?'), findsOneWidget);
    expect(find.textContaining('what index the last item has'), findsOneWidget);
  });

  testWidgets(
      'TC-AIUI-06 when the tutor is down the person sees a plain message and can keep working',
      (tester) async {
    final api = FakeApi(
        askError: const ApiProblem('The tutor is not available right now.',
            recovery: 'You can keep working; try again later.'));
    await pump(tester, '/lab/python-hello-001', MemoryUserStore(), api);
    await tester.enterText(find.byKey(const Key('tutor-input')), 'help');
    await tester.tap(find.byKey(const Key('tutor-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not available right now'), findsOneWidget);
    expect(find.byKey(const Key('tutor-send')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TC-AIUI-07 the roadmap stays with the data file format: it round-trips and a damaged one is dropped',
      (tester) async {
    final r = SavedRoadmap.fromApi({
      'title': 'T',
      'steps': [
        {'kind': 'lab', 'lab_id': 'python-hello-001', 'title': 'a', 'why': 'b'}
      ]
    }, source: 'job_description', now: DateTime(2026, 11, 11))!;
    final d = const UserData(uid: 'u').copyWith(roadmap: r);
    final back = UserData.fromJson(d.toJson(), uid: 'u');
    expect(back.roadmap!.steps.single.labId, 'python-hello-001');
    final json = d.toJson();
    json['roadmap'] = {'title': 5, 'steps': 'x', 'source': 'topic'};
    expect(UserData.fromJson(json, uid: 'u').roadmap, isNull);
  });

  testWidgets(
      'TC-AIUI-08 interview questions are made from the same text and shown as practice material',
      (tester) async {
    final api = FakeApi();
    await pump(tester, '/paths', MemoryUserStore(), api);
    await tester.enterText(
        find.byKey(const Key('planner-text')), 'Python backend job');
    await tester.tap(find.byKey(const Key('planner-interview')));
    await tester.pumpAndSettle();
    expect(api.lastInterviewRequest, {
      'kind': 'job_description',
      'text': 'Python backend job',
      'level': 'beginner'
    });
    expect(api.calls, ['interview'], reason: 'the roadmap is not requested');
    expect(find.byKey(const Key('interview-card')), findsOneWidget);
    expect(find.text('0 of 4 practised'), findsOneWidget);
    expect(find.textContaining('Practice only'), findsOneWidget);
    expect(find.textContaining('What is a branch in Git?'), findsOneWidget);
    expect(find.text('isolation'), findsNothing,
        reason:
            'the good-answer points stay hidden until the question is opened');
  });

  testWidgets(
      'TC-AIUI-09 opening a question shows the hint and the good-answer points, and practised marks are saved',
      (tester) async {
    final store = MemoryUserStore();
    await pump(tester, '/paths', store, FakeApi());
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-interview')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('interview-q-0')));
    await tester.tap(find.textContaining('What is a branch in Git?'));
    await tester.pumpAndSettle();
    expect(find.text('Think about parallel work.'), findsOneWidget);
    expect(find.text('• isolation'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('interview-practised-0')));
    await tester.tap(find.byKey(const Key('interview-practised-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 4 practised'), findsOneWidget);
    final saved = (await store.load('asha-uid')).interview!;
    expect(saved.practised, {0});
    expect((await store.load('bob-uid')).interview, isNull);
    await tester.tap(find.byKey(const Key('interview-practised-0')));
    await tester.pumpAndSettle();
    expect(find.text('0 of 4 practised'), findsOneWidget);
  });

  testWidgets(
      'TC-AIUI-10 a coach problem is shown plainly, empty input sends nothing, and the questions can be removed',
      (tester) async {
    final api = FakeApi(
        interviewError: const ApiProblem(
            'The interview coach is not available right now.',
            recovery: 'You can keep working; try again later.'));
    await pump(tester, '/paths', MemoryUserStore(), api);
    await tester.tap(find.byKey(const Key('planner-interview')));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Paste a job description first'), findsOneWidget);
    expect(api.calls, isEmpty);
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-interview')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const Key('planner-error')),
            matching: find.textContaining('not available')),
        findsOneWidget);

    await pump(tester, '/paths', MemoryUserStore(), FakeApi());
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-interview')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('interview-clear')));
    await tester.tap(find.byKey(const Key('interview-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('interview-card')), findsNothing);
  });

  testWidgets(
      'TC-AIUI-11 a damaged interview answer or file is rejected and the data round-trips',
      (tester) async {
    expect(
        SavedInterview.parse({'title': 'x', 'questions': 'no'},
            source: 'topic', createdAt: ''),
        isNull);
    expect(
        SavedInterview.parse({
          'title': 'x',
          'questions': [
            {'kind': 'trick', 'question': 'q'}
          ]
        }, source: 'topic', createdAt: ''),
        isNull);
    final ok = SavedInterview.parse({
      'title': 'T',
      'questions': [
        {
          'kind': 'concept',
          'question': 'q1',
          'hint': 'h',
          'good_answer_covers': List.filled(9, 'c'),
          'skills': List.filled(9, 's')
        },
      ],
      'practised': [0, 5, -1, 'x'],
    }, source: 'topic', createdAt: '2026')!;
    expect(ok.questions.single.covers.length, 3);
    expect(ok.questions.single.skills.length, 4);
    expect(ok.practised, {0},
        reason: 'out-of-range and wrong-type marks are dropped');
    final d =
        const UserData(uid: 'u').copyWith(interview: ok.withPractised(0, true));
    final back = UserData.fromJson(d.toJson(), uid: 'u');
    expect(back.interview!.questions.single.question, 'q1');
    expect(back.interview!.practised, {0});
  });
}
