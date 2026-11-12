// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-ENV-001..005, FR-WS-001..005, NFR-USE-001
// Capability: CAP-VSCODE-LAUNCHER (ADR-022). Test IDs: TC-LNK-40..49
// Implemented here: what the learner sees when they press Start: detect VS Code, plan, approve, install, open

import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:desktop/worker/process_worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWorker implements WorkerClient {
  FakeWorker(
      {this.editorFound = true,
      this.guideAction = 'none',
      this.guideAvailable = true,
      this.installStatus = 'installed',
      this.launchOk = true,
      this.sessionSteps = const []});
  bool editorFound;
  String guideAction;
  bool guideAvailable;
  String installStatus;
  bool launchOk;
  List<Map<String, dynamic>> sessionSteps;
  final List<String> calls = [];
  final List<Map<String, dynamic>> payloads = [];

  @override
  Future<Map<String, dynamic>> send(
      String channel, Map<String, dynamic> data) async {
    calls.add(channel);
    payloads.add(data);
    switch (channel) {
      case 'companion:status':
        return {
          'editor': editorFound
              ? {
                  'found': true,
                  'name': 'Visual Studio Code',
                  'version': '1.144.0',
                  'path': '/usr/bin/code'
                }
              : {
                  'found': false,
                  'reasons': ['VS Code was not found in the usual places.'],
                  'help':
                      'Install Visual Studio Code from code.visualstudio.com, then come back and start the lab again.'
                },
          'guide': {
            'available': guideAvailable,
            'action': guideAction,
            'lines': guideAvailable
                ? [
                    'DevPilot Guide 0.1.0 will be installed into Visual Studio Code 1.144.0 (/usr/bin/code).',
                    'It talks only to DevPilot on this computer and does not use the internet.'
                  ]
                : [
                    'The DevPilot Guide extension is missing from this DevPilot install. Reinstall DevPilot.'
                  ],
          },
        };
      case 'companion:install':
        return {
          'status': installStatus,
          'message': installStatus == 'installed'
              ? 'The DevPilot Guide is installed.'
              : 'Visual Studio Code could not install the guide. It may be blocked on this computer.'
        };
      case 'companion:launch':
        return launchOk
            ? {
                'ok': true,
                'message': 'VS Code is opening your lab.',
                'labRoot': '/home/u/DevPilotLabs/python-hello-001'
              }
            : {
                'ok': false,
                'message':
                    'Visual Studio Code could not open the lab. Close any stuck VS Code windows and try again.'
              };
      case 'companion:sessionState':
        return {
          'active': sessionSteps.isNotEmpty,
          'labRoot': '/home/u/DevPilotLabs/python-hello-001',
          'steps': sessionSteps,
          'passed': sessionSteps.where((s) => s['state'] == 'pass').length,
          'total': sessionSteps.length,
          'finishRequested': false
        };
    }
    throw WorkerException(
        code: 'failed', message: 'unexpected $channel', recovery: '');
  }
}

Future<void> openCourse(WidgetTester tester, FakeWorker w) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [workerClientProvider.overrideWithValue(w)],
    child: DevPilotApp(
        router: createRouter(initialLocation: '/course/python-hello-001')),
  ));
  await tester.pumpAndSettle();
  // The status bar asks the worker about VS Code once when the app opens. That is not part of these flows.
  w.calls.clear();
  w.payloads.clear();
}

Future<void> pressStart(WidgetTester tester) async {
  await tester.tap(find.descendant(
      of: find.byKey(const Key('course-header')),
      matching: find.text('Start')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-LNK-40 VS Code found and guide already installed: opens the lab and shows the lab page, no dialog',
      (tester) async {
    final w = FakeWorker();
    await openCourse(tester, w);
    await pressStart(tester);
    expect(w.calls.take(2), ['companion:status', 'companion:launch']);
    expect(w.payloads[1], {'labId': 'python-hello-001'});
    expect(find.byKey(const Key('breadcrumb')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      'TC-LNK-41 guide needs installing: the plan is shown in plain words and Cancel does nothing',
      (tester) async {
    final w = FakeWorker(guideAction: 'install');
    await openCourse(tester, w);
    await pressStart(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('does not use the internet'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(w.calls, ['companion:status']);
    expect(find.byKey(const Key('course-header')), findsOneWidget);
  });

  testWidgets(
      'TC-LNK-42 approving the plan installs first (with approved: true) and then opens the lab',
      (tester) async {
    final w = FakeWorker(guideAction: 'install');
    await openCourse(tester, w);
    await pressStart(tester);
    await tester.tap(find.text('Install and open lab'));
    await tester.pumpAndSettle();
    expect(w.calls.take(3),
        ['companion:status', 'companion:install', 'companion:launch']);
    expect(w.payloads[1], {'approved': true});
    expect(find.byKey(const Key('breadcrumb')), findsOneWidget);
  });

  testWidgets('TC-LNK-43 no VS Code: explains what to do, starts nothing',
      (tester) async {
    final w = FakeWorker(editorFound: false);
    await openCourse(tester, w);
    await pressStart(tester);
    expect(find.text('VS Code is needed'), findsOneWidget);
    expect(find.textContaining('code.visualstudio.com'), findsOneWidget);
    expect(w.calls, ['companion:status']);
  });

  testWidgets(
      'TC-LNK-44 guide missing from this DevPilot install: says so, starts nothing',
      (tester) async {
    final w = FakeWorker(guideAvailable: false);
    await openCourse(tester, w);
    await pressStart(tester);
    expect(find.textContaining('missing from this DevPilot install'),
        findsWidgets);
    expect(w.calls, ['companion:status']);
  });

  testWidgets(
      'TC-LNK-45 install failure is shown in plain words and the lab is not opened',
      (tester) async {
    final w = FakeWorker(guideAction: 'install', installStatus: 'failed');
    await openCourse(tester, w);
    await pressStart(tester);
    await tester.tap(find.text('Install and open lab'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not install the guide'), findsOneWidget);
    expect(w.calls, ['companion:status', 'companion:install']);
    expect(find.byKey(const Key('course-header')), findsOneWidget);
  });

  testWidgets(
      'TC-LNK-46 launch failure stays on the course page with the message',
      (tester) async {
    final w = FakeWorker(launchOk: false);
    await openCourse(tester, w);
    await pressStart(tester);
    expect(find.textContaining('could not open the lab'), findsOneWidget);
    expect(find.byKey(const Key('course-header')), findsOneWidget);
  });

  testWidgets('TC-LNK-47 a worker that is not available gives a plain message',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        workerClientProvider.overrideWithValue(
            UnavailableWorkerClient('DevPilot helper was not found.'))
      ],
      child: DevPilotApp(
          router: createRouter(initialLocation: '/course/python-hello-001')),
    ));
    await tester.pumpAndSettle();
    await pressStart(tester);
    expect(find.textContaining('helper was not found'), findsOneWidget);
  });

  testWidgets(
      'TC-LNK-48 the lab page follows the open lab: steps, Practice score, and stops polling when closed',
      (tester) async {
    final w = FakeWorker(sessionSteps: [
      {'id': 'setup', 'title': 'Open the starter file', 'state': 'pass'},
      {'id': 'greet', 'title': 'Write greet', 'state': 'todo'},
    ]);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [workerClientProvider.overrideWithValue(w)],
      child: DevPilotApp(
          router: createRouter(initialLocation: '/lab/python-hello-001')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Open the starter file'), findsOneWidget);
    expect(find.textContaining('Practice score: 50 / 100'), findsOneWidget);
    w.sessionSteps = [
      {'id': 'setup', 'title': 'Open the starter file', 'state': 'pass'},
      {'id': 'greet', 'title': 'Write greet', 'state': 'pass'},
    ];
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('Practice score: 100 / 100'), findsOneWidget);
    final before = w.calls.length;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(w.calls.length, before);
  });

  testWidgets('TC-LNK-49 a lab that is not open says so and offers Start',
      (tester) async {
    final w = FakeWorker();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [workerClientProvider.overrideWithValue(w)],
      child: DevPilotApp(
          router: createRouter(initialLocation: '/lab/python-hello-001')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('This lab is not open'), findsOneWidget);
    await tester.tap(find.text('Start this lab'));
    await tester.pumpAndSettle();
    expect(
        w.calls, containsAllInOrder(['companion:status', 'companion:launch']));
  });
}
