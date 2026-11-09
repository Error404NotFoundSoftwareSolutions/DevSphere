// Capability: CAP-PROFILE-DATA, CAP-CATALOG, CAP-CREDENTIALS. Tests: TC-PGS-01..12
// Implemented here: the rail pages show the signed-in person's own data, never someone else's, and are honest
// about verification.
import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/data/user_data.dart';
import 'package:desktop/data/user_store.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const asha = AuthUser(uid: 'asha-uid', email: 'asha@example.com', displayName: 'Asha Rao');
const bob = AuthUser(uid: 'bob-uid', email: 'bob@example.com', displayName: 'Bob');

List<StepProgress> steps(List<String> states) => [
      for (var i = 0; i < states.length; i++) StepProgress(id: 's$i', title: 'Step $i', state: states[i]),
    ];

Future<MemoryUserStore> seededStore() async {
  final now = DateTime.now();
  final store = MemoryUserStore();
  // Asha finished the first lab and is half way through the second. Bob has done nothing.
  var d = const UserData(uid: 'asha-uid');
  d = d.withLabState(labId: 'python-hello-001', title: 'Hello', labRoot: '/home/asha/DevPilotLabs/python-hello-001', steps: steps(['pass', 'pass']), now: now);
  d = d.withLabState(labId: 'oss-first-contribution-001', title: 'OSS', labRoot: '/home/asha/DevPilotLabs/oss-first-contribution-001', steps: steps(['pass', 'pass', 'todo', 'todo']), now: now);
  await store.save(d);
  return store;
}

Future<void> pumpPage(WidgetTester tester, String location, MemoryUserStore store, {AuthUser? user}) async {
  AuthSession.instance.signOut();
  if (user != null) AuthSession.instance.signIn(user);
  addTearDown(AuthSession.instance.signOut);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workerClientProvider.overrideWithValue(MockWorkerClient()),
      userStoreProvider.overrideWithValue(store),
    ],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final page in ['catalog', 'paths', 'credentials', 'workspaces']) {
    testWidgets('TC-PGS-01 $page asks a signed-out visitor to sign in and shows no data', (tester) async {
      await pumpPage(tester, '/$page', await seededStore());
      expect(find.byKey(const Key('signed-out-notice')), findsOneWidget);
      expect(find.textContaining('Practice complete'), findsNothing);
    });
  }

  testWidgets('TC-PGS-02 the catalog shows this person\'s status on each card and filters', (tester) async {
    await pumpPage(tester, '/catalog', await seededStore(), user: asha);
    expect(find.descendant(of: find.byKey(const Key('catalog-card-python-hello-001')), matching: find.text('Practice complete')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('catalog-card-oss-first-contribution-001')), matching: find.text('In progress: 2 of 4 checks')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('catalog-card-rest-api-001')), matching: find.text('Coming soon')), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-Available now')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-card-rest-api-001')), findsNothing, reason: 'planned items are hidden by "Available now"');
    expect(find.byKey(const Key('catalog-card-python-hello-001')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('catalog-search')), 'zzz nothing');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-empty')), findsOneWidget);
  });

  testWidgets('TC-PGS-03 the next person on the same computer sees their own empty catalog', (tester) async {
    await pumpPage(tester, '/catalog', await seededStore(), user: bob);
    expect(find.text('Practice complete'), findsNothing);
    expect(find.textContaining('In progress'), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('catalog-card-python-hello-001')), matching: find.text('Not started')), findsOneWidget);
  });

  testWidgets('TC-PGS-04 paths show progress and mark the next lab to do', (tester) async {
    await pumpPage(tester, '/paths', await seededStore(), user: asha);
    final path = find.byKey(const Key('path-first-project-to-first-pr'));
    expect(find.descendant(of: path, matching: find.text('1 of 3 done')), findsOneWidget);
    final next = find.descendant(of: find.byKey(const Key('path-item-oss-first-contribution-001')), matching: find.text('Up next'));
    expect(next, findsOneWidget, reason: 'the first available lab that is not complete');
    expect(find.descendant(of: find.byKey(const Key('path-item-python-hello-001')), matching: find.text('Up next')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('path-item-git-first-commit-001')), matching: find.text('Coming soon')), findsOneWidget);
  });

  testWidgets('TC-PGS-05 credentials are honest: practice results pending verification, zero badges', (tester) async {
    await pumpPage(tester, '/credentials', await seededStore(), user: asha);
    expect(find.descendant(of: find.byKey(const Key('stat-badges')), matching: find.text('0')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('stat-completed')), matching: find.text('1')), findsOneWidget);
    expect(find.byKey(const Key('completed-python-hello-001')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('completed-python-hello-001')), matching: find.text('Pending verification')), findsOneWidget);
    expect(find.byKey(const Key('inprogress-oss-first-contribution-001')), findsOneWidget);
    expect(find.byKey(const Key('verification-note')), findsOneWidget);
    expect(find.textContaining('Badge earned'), findsNothing);
    expect(find.text('Python basics'), findsOneWidget, reason: 'skills from the finished lab');
  });

  testWidgets('TC-PGS-06 another person\'s credentials page is empty', (tester) async {
    await pumpPage(tester, '/credentials', await seededStore(), user: bob);
    expect(find.byKey(const Key('credentials-empty')), findsOneWidget);
    expect(find.byKey(const Key('completed-python-hello-001')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('stat-completed')), matching: find.text('0')), findsOneWidget);
  });

  testWidgets('TC-PGS-07 workspaces list this person\'s lab folders with a way to open them', (tester) async {
    await pumpPage(tester, '/workspaces', await seededStore(), user: asha);
    expect(find.byKey(const Key('workspace-python-hello-001')), findsOneWidget);
    expect(find.text('/home/asha/DevPilotLabs/oss-first-contribution-001'), findsOneWidget);
    expect(find.text('Open in VS Code'), findsNWidgets(2));
    expect(find.byKey(const Key('editor-card')), findsOneWidget);
  });

  testWidgets('TC-PGS-08 a person with no labs sees an empty workspaces page, not someone else\'s folders', (tester) async {
    await pumpPage(tester, '/workspaces', await seededStore(), user: bob);
    expect(find.byKey(const Key('workspaces-empty')), findsOneWidget);
    expect(find.textContaining('/home/asha'), findsNothing);
  });

  testWidgets('TC-PGS-09 the dashboard resumes this person\'s unfinished lab and shows real numbers', (tester) async {
    await pumpPage(tester, '/dashboard', await seededStore(), user: asha);
    expect(find.descendant(of: find.byKey(const Key('hero')), matching: find.text('Resume')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('hero')), matching: find.text('Your first open-source contribution')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('weekly-card')), matching: find.text('4')), findsOneWidget, reason: '4 checks passed today');
    expect(find.descendant(of: find.byKey(const Key('badges-card')), matching: find.text('0')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('streak')), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('TC-PGS-10 a new person sees a clean dashboard: no streak, no weekly checks, start offered', (tester) async {
    await pumpPage(tester, '/dashboard', await seededStore(), user: bob);
    expect(find.descendant(of: find.byKey(const Key('hero')), matching: find.text('Start')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('streak')), matching: find.text('0')), findsOneWidget);
    expect(find.byKey(const Key('achievements-empty')), findsOneWidget);
  });

  testWidgets('TC-PGS-11 the profile page opens for the signed-in person, not a made-up student', (tester) async {
    await pumpPage(tester, '/profile', await seededStore(), user: asha);
    expect(find.text('Asha Rao'), findsWidgets);
    expect(find.textContaining('Student User'), findsNothing);
  });

  testWidgets('TC-PGS-12 the course page shows this person\'s progress and a clear state for planned items', (tester) async {
    await pumpPage(tester, '/course/oss-first-contribution-001', await seededStore(), user: asha);
    expect(find.descendant(of: find.byKey(const Key('course-header')), matching: find.text('Resume')), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byKey(const Key('course-progress')));
    expect(bar.value, 0.5);
    await pumpPage(tester, '/course/rest-api-001', await seededStore(), user: asha);
    expect(find.descendant(of: find.byKey(const Key('course-header')), matching: find.text('Coming soon')), findsOneWidget);
  });
}
