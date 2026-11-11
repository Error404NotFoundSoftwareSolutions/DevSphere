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

const asha = AuthUser(uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha');
const bob = AuthUser(uid: 'bob-uid', email: 'bob@example.com', displayName: 'Bob');

class FakeApi implements DevPilotApi {
  FakeApi({this.roadmapError, this.askError});
  final ApiProblem? roadmapError;
  final ApiProblem? askError;
  final calls = <String>[];
  Map<String, dynamic>? lastRoadmapRequest;
  String? lastLanguage;

  @override
  Future<Map<String, dynamic>> roadmap({required String kind, required String text, String level = 'beginner'}) async {
    calls.add('roadmap');
    lastRoadmapRequest = {'kind': kind, 'text': text, 'level': level};
    if (roadmapError != null) throw roadmapError!;
    return {
      'title': 'Backend intern path',
      'steps': [
        {'kind': 'lab', 'lab_id': 'python-hello-001', 'title': 'Hello, Python', 'why': 'Learn the basics.', 'skills': ['Python']},
        {'kind': 'lab', 'lab_id': 'oss-first-contribution-001', 'title': 'OSS', 'why': 'Work like a team.', 'skills': ['Git']},
        {'kind': 'generate', 'lab_id': null, 'title': 'REST APIs with FastAPI', 'why': 'The job asks for APIs.', 'skills': ['FastAPI']},
      ],
    };
  }

  @override
  Future<String> attemptFor(String labId) async {
    calls.add('attempt:$labId');
    return 'att-1';
  }

  @override
  Future<TutorAnswer> ask({required String attemptId, required String question, String language = 'en', String? code}) async {
    calls.add('ask');
    lastLanguage = language;
    if (askError != null) throw askError!;
    return const TutorAnswer(answer: 'Think about what index the last item has.', level: 3);
  }
}

Future<void> pump(WidgetTester tester, String location, MemoryUserStore store, FakeApi api, {AuthUser? user = asha}) async {
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
  testWidgets('TC-AIUI-01 pasting a job description builds a roadmap with real labs and labs that do not exist yet', (tester) async {
    final api = FakeApi();
    await pump(tester, '/paths', MemoryUserStore(), api);
    expect(find.byKey(const Key('saved-roadmap')), findsNothing);
    await tester.enterText(find.byKey(const Key('planner-text')), 'Junior backend developer. Python, Git, FastAPI.');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(api.lastRoadmapRequest, {'kind': 'job_description', 'text': 'Junior backend developer. Python, Git, FastAPI.', 'level': 'beginner'});
    expect(find.byKey(const Key('saved-roadmap')), findsOneWidget);
    expect(find.text('Backend intern path'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('roadmap-step-0')), matching: find.text('Open')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('roadmap-step-2')), matching: find.text('No lab yet')), findsOneWidget);
    expect(find.byKey(const Key('planner-error')), findsNothing);
  });

  testWidgets('TC-AIUI-02 the roadmap is saved for this person only and survives a restart', (tester) async {
    final store = MemoryUserStore();
    await pump(tester, '/paths', store, FakeApi());
    await tester.enterText(find.byKey(const Key('planner-text')), 'anything');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect((await store.load('asha-uid')).roadmap!.steps.length, 3);
    expect((await store.load('bob-uid')).roadmap, isNull);
    await pump(tester, '/paths', store, FakeApi(), user: asha);
    expect(find.byKey(const Key('saved-roadmap')), findsOneWidget, reason: 'comes back from the saved data');
    await pump(tester, '/paths', store, FakeApi(), user: bob);
    expect(find.byKey(const Key('saved-roadmap')), findsNothing, reason: 'the next person does not see it');
  });

  testWidgets('TC-AIUI-03 empty input, a service problem and removing a roadmap all behave', (tester) async {
    final api = FakeApi(roadmapError: const ApiProblem('The planner is not available right now.', recovery: 'You can keep working; try again later.'));
    await pump(tester, '/paths', MemoryUserStore(), api);
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paste a job description first'), findsOneWidget);
    expect(api.calls, isEmpty, reason: 'nothing is sent for empty input');
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('planner-error')), matching: find.textContaining('try again later')), findsOneWidget);

    final ok = FakeApi();
    await pump(tester, '/paths', MemoryUserStore(), ok);
    await tester.enterText(find.byKey(const Key('planner-text')), 'x');
    await tester.tap(find.byKey(const Key('planner-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roadmap-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved-roadmap')), findsNothing);
  });

  testWidgets('TC-AIUI-04 a malformed answer from the service is rejected, not half shown', (tester) async {
    expect(SavedRoadmap.fromApi({'title': 'x', 'steps': 'nope'}, source: 'topic', now: DateTime(2026)), isNull);
    expect(SavedRoadmap.fromApi({'title': 'x', 'steps': [{'kind': 'lab', 'lab_id': '../../x', 'title': 't', 'why': 'w'}]}, source: 'topic', now: DateTime(2026)), isNull, reason: 'a lab step needs a valid lab id');
    final r = SavedRoadmap.fromApi({
      'title': 'x',
      'steps': [
        {'kind': 'root-shell', 'title': 'bad'},
        {'kind': 'generate', 'lab_id': null, 'title': 'ok', 'why': 'w', 'skills': List.filled(20, 's')},
      ],
    }, source: 'topic', now: DateTime(2026))!;
    expect(r.steps.length, 1);
    expect(r.steps.single.skills.length, 6);
  });

  testWidgets('TC-AIUI-05 the tutor sends the question in the chosen language and shows the answer', (tester) async {
    final api = FakeApi();
    await pump(tester, '/lab/python-hello-001', MemoryUserStore(), api);
    await tester.ensureVisible(find.byKey(const Key('tutor-panel')));
    await tester.tap(find.byKey(const Key('tutor-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ಕನ್ನಡ').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tutor-input')), 'Why IndexError?');
    await tester.tap(find.byKey(const Key('tutor-send')));
    await tester.pumpAndSettle();
    expect(api.calls, ['attempt:python-hello-001', 'ask']);
    expect(api.lastLanguage, 'kn');
    expect(find.text('Why IndexError?'), findsOneWidget);
    expect(find.textContaining('what index the last item has'), findsOneWidget);
  });

  testWidgets('TC-AIUI-06 when the tutor is down the person sees a plain message and can keep working', (tester) async {
    final api = FakeApi(askError: const ApiProblem('The tutor is not available right now.', recovery: 'You can keep working; try again later.'));
    await pump(tester, '/lab/python-hello-001', MemoryUserStore(), api);
    await tester.enterText(find.byKey(const Key('tutor-input')), 'help');
    await tester.tap(find.byKey(const Key('tutor-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not available right now'), findsOneWidget);
    expect(find.byKey(const Key('tutor-send')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-AIUI-07 the roadmap stays with the data file format: it round-trips and a damaged one is dropped', (tester) async {
    final r = SavedRoadmap.fromApi({'title': 'T', 'steps': [{'kind': 'lab', 'lab_id': 'python-hello-001', 'title': 'a', 'why': 'b'}]}, source: 'job_description', now: DateTime(2026, 11, 11))!;
    final d = const UserData(uid: 'u').copyWith(roadmap: r);
    final back = UserData.fromJson(d.toJson(), uid: 'u');
    expect(back.roadmap!.steps.single.labId, 'python-hello-001');
    final json = d.toJson();
    json['roadmap'] = {'title': 5, 'steps': 'x', 'source': 'topic'};
    expect(UserData.fromJson(json, uid: 'u').roadmap, isNull);
  });
}
