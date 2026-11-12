// Capability: CAP-CREDENTIALS. Tests: TC-CRED-20..25
// Implemented here: claiming a credential for a finished lab, the honest tier label, sharing with a chosen name, and
// stopping sharing. The service is a stand-in; the real rules are tested in services/api.
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

const asha = AuthUser(
    uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha Rao');

class CredApi extends DevPilotApiStub {
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
  CredApi({this.claimError, this.local = false, List<Credential>? existing})
      : stored = [...?existing];
  final ApiProblem? claimError;
  final bool local;
  final List<Credential> stored;
  final claims = <Map<String, Object?>>[];
  final sharing = <Map<String, Object?>>[];

  @override
  Future<List<Credential>> credentials() async => [...stored];

  @override
  Future<Credential> claimCredential(
      {required String labId,
      required Map<String, bool> checks,
      required String startedAt,
      required String completedAt}) async {
    claims.add({
      'lab': labId,
      'checks': checks,
      'start': startedAt,
      'end': completedAt
    });
    if (claimError != null) throw claimError!;
    final c = Credential(
        id: 'c_abc',
        labId: labId,
        title: 'Hello',
        tier: 'attested',
        issuedAt: '2026-11-11T10:00:00+00:00');
    stored.add(c);
    return c;
  }

  @override
  Future<Credential> setSharing(String id,
      {required bool isPublic, String displayName = ''}) async {
    sharing.add({'public': isPublic, 'name': displayName});
    final c = Credential(
        id: id,
        labId: 'python-hello-001',
        title: 'Hello',
        tier: 'attested',
        issuedAt: '2026-11-11T10:00:00+00:00',
        isPublic: isPublic,
        displayName: displayName);
    stored
      ..clear()
      ..add(c);
    return c;
  }

  @override
  String publicLink(String id) => 'https://example.test/c/$id';
  @override
  bool get isLocalService => local;

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
  Future<Map<String, dynamic>> generateLab(
          {required String topic, String level = 'beginner'}) =>
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

Future<void> pumpCreds(WidgetTester tester, CredApi api) async {
  final store = MemoryUserStore();
  final now = DateTime.now();
  await store.save(const UserData(uid: 'asha-uid').withLabState(
    labId: 'python-hello-001',
    title: 'Hello',
    labRoot: '/x',
    steps: [
      const StepProgress(id: 'visible-greet', title: 'A', state: 'pass'),
      const StepProgress(id: 'protected', title: 'B', state: 'pass')
    ],
    now: now,
  ));
  AuthSession.instance.signOut();
  AuthSession.instance.signIn(asha);
  addTearDown(AuthSession.instance.signOut);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(MockWorkerClient()),
      userStoreProvider.overrideWithValue(store),
      devPilotApiProvider.overrideWithValue(api),
    ],
    child: DevPilotApp(router: createRouter(initialLocation: '/credentials')),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-CRED-20 a finished lab can be claimed; the claim carries every check result and the tier is honest',
      (tester) async {
    final api = CredApi();
    await pumpCreds(tester, api);
    expect(find.text('Not claimed yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-python-hello-001')));
    await tester.pumpAndSettle();
    expect(api.claims.single['lab'], 'python-hello-001');
    expect(api.claims.single['checks'],
        {'visible-greet': true, 'protected': true});
    expect(find.byKey(const Key('tier-python-hello-001')), findsOneWidget);
    expect(find.text('Completed on your computer'), findsOneWidget);
    expect(find.text('Verified'), findsNothing,
        reason: 'a self-run result is never called Verified');
    expect(
        find.descendant(
            of: find.byKey(const Key('stat-badges')), matching: find.text('0')),
        findsOneWidget);
  });

  testWidgets(
      'TC-CRED-21 when the service refuses, the reason is shown and nothing is claimed',
      (tester) async {
    final api = CredApi(
        claimError: const ApiProblem('This lab does not give a credential.',
            recovery: 'Practice labs are for learning only.'));
    await pumpCreds(tester, api);
    await tester.tap(find.byKey(const Key('claim-python-hello-001')));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not give a credential'), findsOneWidget);
    expect(find.text('Not claimed yet'), findsOneWidget);
  });

  testWidgets(
      'TC-CRED-22 sharing needs a name, then shows the public link; stopping sharing takes it away',
      (tester) async {
    final api = CredApi(existing: const [
      Credential(
          id: 'c_abc',
          labId: 'python-hello-001',
          title: 'Hello',
          tier: 'attested',
          issuedAt: '2026-11-11')
    ]);
    await pumpCreds(tester, api);
    await tester.tap(find.byKey(const Key('share-python-hello-001')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not your email'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('share-name')))
            .controller!
            .text,
        'Asha Rao',
        reason: 'suggested from the account, editable');
    await tester.enterText(find.byKey(const Key('share-name')), 'Asha R');
    await tester.tap(find.byKey(const Key('share-start')));
    await tester.pumpAndSettle();
    expect(api.sharing.single, {'public': true, 'name': 'Asha R'});
    expect(find.text('https://example.test/c/c_abc'), findsOneWidget);
    expect(find.byKey(const Key('share-local-note')), findsNothing);
    await tester.tap(find.byKey(const Key('share-stop')));
    await tester.pumpAndSettle();
    expect(api.sharing.last['public'], false);
    expect(find.byKey(const Key('share-link')), findsNothing);
  });

  testWidgets(
      'TC-CRED-23 a link to a service on this computer says it only works here',
      (tester) async {
    final api = CredApi(local: true, existing: const [
      Credential(
          id: 'c_abc',
          labId: 'python-hello-001',
          title: 'Hello',
          tier: 'attested',
          issuedAt: '2026-11-11')
    ]);
    await pumpCreds(tester, api);
    await tester.tap(find.byKey(const Key('share-python-hello-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-local-note')), findsOneWidget);
  });

  testWidgets(
      'TC-CRED-24 the page still works when the service cannot be reached',
      (tester) async {
    await pumpCreds(tester, CredApi());
    expect(find.byKey(const Key('completed-python-hello-001')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('TC-CRED-25 a credential from the service is read safely', () {
    expect(
        Credential.tryParse({
          'id': 'c_1',
          'lab_id': 'l',
          'lab_title': 'T',
          'tier': 'verified',
          'issued_at': 'x',
          'public': true,
          'display_name': 'A'
        })!
            .verified,
        isTrue);
    expect(
        Credential.tryParse({
          'id': 'c_1',
          'lab_id': 'l',
          'lab_title': 'T',
          'tier': 'surprise'
        })!
            .verified,
        isFalse,
        reason: 'unknown tiers are never treated as verified');
    expect(Credential.tryParse('junk'), isNull);
    expect(Credential.tryParse({'id': 1}), isNull);
  });
}
