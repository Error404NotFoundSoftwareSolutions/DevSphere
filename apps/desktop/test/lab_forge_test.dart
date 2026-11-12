// Capability: CAP-LAB-FORGE. Tests: TC-FORGE-10..17
// Implemented here: Lab Forge in the app: generate, preview, consent, install through the worker, keep the lab with
// the right person, and open it like any lab.
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

import 'support/api_stub.dart';

const asha =
    AuthUser(uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha');
const bob =
    AuthUser(uid: 'bob-uid', email: 'bob@example.com', displayName: 'Bob');

Map<String, dynamic> learnerLab() => {
      'lab_id': 'fix-index-error-cart',
      'title': 'Fix an IndexError in a Shopping Cart',
      'steps': [
        {
          'id': 'step1',
          'title': 'Read the error',
          'content_md': 'x',
          'check': false
        },
        {
          'id': 'step2',
          'title': 'Fix the bug',
          'content_md': 'y',
          'check': true
        },
      ],
      'starter': [
        {'path': 'cart.py', 'content': 'x'}
      ],
      'visible_tests': [
        {'path': 'tests/visible/test_cart.py', 'content': 'x'}
      ],
    };

class ForgeApi extends DevPilotApiStub {
  @override
  Future<Map<String, dynamic>> explainError(
          {required String errorText, String? code, String language = 'en'}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> reviewCode(
          {required String code,
          String filename = '',
          String goal = '',
          String language = 'en'}) =>
      throw UnimplementedError();

  @override
  Future<List<Credential>> credentials() => throw UnimplementedError();
  @override
  Future<Credential> claimCredential(
          {required String labId,
          required Map<String, bool> checks,
          required String startedAt,
          required String completedAt}) =>
      throw UnimplementedError();
  @override
  Future<Credential> setSharing(String id,
          {required bool isPublic, String displayName = ''}) =>
      throw UnimplementedError();
  @override
  String publicLink(String id) => '';
  @override
  bool get isLocalService => true;
  ForgeApi({this.error, this.verified = true});
  final ApiProblem? error;
  final bool verified;
  final requests = <Map<String, String>>[];

  @override
  Future<Map<String, dynamic>> generateLab(
      {required String topic, String level = 'beginner'}) async {
    requests.add({'topic': topic, 'level': level});
    if (error != null) throw error!;
    return {
      'status': verified ? 'verified' : 'draft',
      'lab': learnerLab(),
      'verification': {'reference_passes': true, 'starter_fails': true}
    };
  }

  @override
  Future<Map<String, dynamic>> roadmap(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> interview(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      throw UnimplementedError();
  @override
  Future<String> attemptFor(String labId) => throw UnimplementedError();
  @override
  Future<TutorAnswer> ask(
          {required String attemptId,
          required String question,
          String language = 'en',
          String? code}) =>
      throw UnimplementedError();
}

class ForgeWorker extends MockWorkerClient {
  ForgeWorker({this.fail = false});
  final bool fail;
  final installs = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> send(
      String channel, Map<String, dynamic> data) async {
    if (channel == 'labforge:install') {
      installs.add(data);
      if (fail)
        return {
          'ok': false,
          'message': 'This lab was not installed: A lab file is too large.'
        };
      return {
        'ok': true,
        'labId': 'ai-fix-index-error-cart',
        'title': 'Fix an IndexError in a Shopping Cart'
      };
    }
    return super.send(channel, data);
  }
}

Future<void> pump(WidgetTester tester, String location, MemoryUserStore store,
    ForgeApi api, ForgeWorker worker,
    {AuthUser user = asha}) async {
  AuthSession.instance.signOut();
  AuthSession.instance.signIn(user);
  addTearDown(AuthSession.instance.signOut);
  tester.view.physicalSize = const Size(1440, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(worker),
      userStoreProvider.overrideWithValue(store),
      devPilotApiProvider.overrideWithValue(api),
    ],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

Future<void> generate(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key('forge-topic')), 'fix an IndexError');
  await tester.tap(find.byKey(const Key('forge-generate')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-FORGE-10 a topic produces a checked preview with its steps, files and the AI warning',
      (tester) async {
    final api = ForgeApi();
    await pump(tester, '/catalog', MemoryUserStore(), api, ForgeWorker());
    await generate(tester);
    expect(api.requests.single,
        {'topic': 'fix an IndexError', 'level': 'beginner'});
    expect(find.byKey(const Key('forge-preview')), findsOneWidget);
    expect(find.text('Fix an IndexError in a Shopping Cart'), findsOneWidget);
    expect(find.text('Checked: the answer passes the tests'), findsOneWidget);
    expect(find.text('Checked: the starter fails the tests'), findsOneWidget);
    expect(find.textContaining('Practice only, no badge'), findsOneWidget);
    expect(find.textContaining('not reviewed by a person'), findsOneWidget);
    expect(find.textContaining('cart.py'), findsWidgets);
    expect(find.textContaining('2 steps'), findsOneWidget);
  });

  testWidgets(
      'TC-FORGE-11 nothing is installed until the person agrees; then it is installed through the worker',
      (tester) async {
    final worker = ForgeWorker();
    final store = MemoryUserStore();
    await pump(tester, '/catalog', store, ForgeApi(), worker);
    await generate(tester);
    await tester.ensureVisible(find.byKey(const Key('forge-install')));
    await tester.tap(find.byKey(const Key('forge-install')));
    await tester.pumpAndSettle();
    expect(find.textContaining('run Python code on your computer'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(worker.installs, isEmpty, reason: 'cancelled: nothing written');

    await tester.tap(find.byKey(const Key('forge-install')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forge-agree')));
    await tester.pumpAndSettle();
    expect(worker.installs.length, 1);
    expect(worker.installs.single['lab'], isA<Map>());
    expect((worker.installs.single['lab'] as Map)['lab_id'],
        'fix-index-error-cart');
    expect(find.text('Added to your labs.'), findsOneWidget);
    final saved = await store.load('asha-uid');
    expect(saved.generatedLabs.single.labId, 'ai-fix-index-error-cart');
    expect(saved.generatedLabs.single.topic, 'fix an IndexError');
  });

  testWidgets(
      'TC-FORGE-12 the added lab shows in "Labs written for you" and opens as its own lab page',
      (tester) async {
    final store = MemoryUserStore();
    final worker = ForgeWorker();
    await pump(tester, '/catalog', store, ForgeApi(), worker);
    await generate(tester);
    await tester.ensureVisible(find.byKey(const Key('forge-install')));
    await tester.tap(find.byKey(const Key('forge-install')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forge-agree')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generated-ai-fix-index-error-cart')),
        findsOneWidget);
    expect(find.text('AI-generated'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('forge-open')));
    await tester.tap(find.byKey(const Key('forge-open')));
    await tester.pumpAndSettle();
    final header = find.byKey(const Key('course-header'));
    expect(find.text('Fix an IndexError in a Shopping Cart'), findsOneWidget,
        reason:
            'the course page is about this lab, not the first catalogue lab');
    expect(find.descendant(of: header, matching: find.text('Start')),
        findsOneWidget);
  });

  testWidgets('TC-FORGE-13 another person does not see my generated labs',
      (tester) async {
    final store = MemoryUserStore();
    await store
        .save(const UserData(uid: 'asha-uid').copyWith(generatedLabs: const [
      GeneratedLabRef(
          labId: 'ai-fix-index-error-cart',
          title: 'Fix an IndexError',
          topic: 'index',
          createdAt: '2026-11-11T10:00:00'),
    ]));
    await pump(tester, '/catalog', store, ForgeApi(), ForgeWorker(), user: bob);
    expect(find.byKey(const Key('my-generated-labs')), findsNothing);
    await pump(tester, '/catalog', store, ForgeApi(), ForgeWorker(),
        user: asha);
    expect(find.byKey(const Key('generated-ai-fix-index-error-cart')),
        findsOneWidget);
  });

  testWidgets(
      'TC-FORGE-14 empty topic sends nothing, a service problem and an unverified answer are shown plainly',
      (tester) async {
    final api = ForgeApi(
        error: const ApiProblem(
            'The generated lab did not pass its own checks, so it was not created.',
            recovery: 'Try a more specific topic.'));
    await pump(tester, '/catalog', MemoryUserStore(), api, ForgeWorker());
    await tester.tap(find.byKey(const Key('forge-generate')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Type a topic first'), findsOneWidget);
    expect(api.requests, isEmpty);
    await generate(tester);
    expect(
        find.descendant(
            of: find.byKey(const Key('forge-error')),
            matching: find.textContaining('more specific topic')),
        findsOneWidget);
    expect(find.byKey(const Key('forge-preview')), findsNothing);

    final draft = ForgeApi(verified: false);
    await pump(tester, '/catalog', MemoryUserStore(), draft, ForgeWorker());
    await generate(tester);
    expect(find.byKey(const Key('forge-preview')), findsNothing,
        reason: 'only a verified lab is ever shown');
    expect(find.byKey(const Key('forge-error')), findsOneWidget);
  });

  testWidgets(
      'TC-FORGE-15 when the worker refuses the lab the person sees why and nothing is saved',
      (tester) async {
    final store = MemoryUserStore();
    await pump(tester, '/catalog', store, ForgeApi(), ForgeWorker(fail: true));
    await generate(tester);
    await tester.ensureVisible(find.byKey(const Key('forge-install')));
    await tester.tap(find.byKey(const Key('forge-install')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forge-agree')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const Key('forge-error')),
            matching: find.textContaining('too large')),
        findsOneWidget);
    expect((await store.load('asha-uid')).generatedLabs, isEmpty);
  });

  testWidgets('TC-FORGE-16 generated lab entries in a saved file are validated',
      (tester) async {
    final back = UserData.fromJson({
      'version': 1,
      'uid': 'u',
      'generatedLabs': [
        {
          'labId': 'ai-good-lab',
          'title': 'T',
          'topic': 'x',
          'createdAt': '2026'
        },
        {'labId': '../../etc', 'title': 'bad'},
        {
          'labId': 'python-hello-001',
          'title': 'a published lab id must not be claimed'
        },
        'junk',
      ],
    }, uid: 'u');
    expect(back.generatedLabs.map((g) => g.labId), ['ai-good-lab']);
  });
}
