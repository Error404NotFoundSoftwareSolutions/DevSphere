// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-USE-001
// Test ID: TC-DES-003-01..11
// Implemented here: DevPilot shell in the Google-Skills style (header, icon rail), dashboard, course page, lab page

import 'package:desktop/app.dart';
import 'package:desktop/router.dart';
import 'package:desktop/api.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:desktop/ui/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAt(WidgetTester tester, Size size,
    {String location = '/dashboard'}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [workerClientProvider.overrideWithValue(MockWorkerClient())],
    child: DevPilotApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TC-DES-003-01 the header is 64px and the rail 104px at 1440x900, with a status bar underneath',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(tester.getSize(find.byKey(const Key('topbar'))).height, 64);
    expect(tester.getSize(find.byKey(const Key('sidebar'))).width, 104);
    expect(tester.getSize(find.byKey(const Key('statusbar'))).height, 28);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TC-DES-003-02 the rail lists the five sections in order, icon above label',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    const labels = [
      'Dashboard',
      'Catalog',
      'Paths',
      'Credentials',
      'Workspaces'
    ];
    final ys = <double>[];
    for (final l in labels) {
      final f = find.descendant(
          of: find.byKey(const Key('sidebar')), matching: find.text(l));
      expect(f, findsOneWidget, reason: l);
      ys.add(tester.getTopLeft(f).dy);
    }
    expect(ys, orderedEquals([...ys]..sort()));
    final icon = tester.getCenter(find.descendant(
        of: find.byKey(const Key('nav-catalog')), matching: find.byType(Icon)));
    final label = tester.getCenter(find.descendant(
        of: find.byKey(const Key('nav-catalog')),
        matching: find.text('Catalog')));
    expect(icon.dy, lessThan(label.dy));
  });

  testWidgets(
      'TC-DES-003-03 the header has back, the wordmark, search with its key hint, streak, the theme switch and the signed-in avatar',
      (tester) async {
    AuthSession.instance.signIn(const AuthUser(
        uid: 'u', email: 'asha@example.com', displayName: 'Asha Rao'));
    addTearDown(AuthSession.instance.signOut);
    await pumpAt(tester, const Size(1440, 900));
    final bar = find.byKey(const Key('topbar'));
    expect(
        find.descendant(
            of: bar, matching: find.byKey(const Key('shell_back_button'))),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('DevPilot')),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('Ctrl K')),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byKey(const Key('streak'))),
        findsOneWidget);
    expect(
        find.descendant(
            of: bar, matching: find.byKey(const Key('theme-toggle'))),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byKey(const Key('profile'))),
        findsOneWidget);
  });

  testWidgets(
      'TC-DES-003-04 the dashboard has the continue card, the Activities and Paths tabs and a card per lab',
      (tester) async {
    await pumpAt(tester, const Size(1440, 1400));
    expect(
        find.descendant(
            of: find.byKey(const Key('hero')), matching: find.text('Start')),
        findsOneWidget,
        reason: 'nothing started yet, so the card offers Start');
    expect(
        find.descendant(
            of: find.byKey(const Key('tabs')),
            matching: find.text('Activities')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('tabs')), matching: find.text('Paths')),
        findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('activity-$i')), findsOneWidget, reason: 'card $i');
    }
    expect(find.text('Hello, Python: set up, install and run'), findsWidgets);
  });

  testWidgets(
      'TC-DES-003-05 the side column has badges, skills, the week at a glance with seven bars, and the path',
      (tester) async {
    await pumpAt(tester, const Size(1440, 1400));
    for (final k in [
      'badges-card',
      'skills-card',
      'weekly-card',
      'achievements',
      'week-line',
      'streak-line'
    ]) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('day-$i')), findsOneWidget, reason: 'day $i');
    }
  });

  testWidgets(
      'TC-DES-003-06 no overflow at 1440x900, 1280x800, 1100x700 and 800x600',
      (tester) async {
    for (final loc in [
      '/dashboard',
      '/catalog',
      '/paths',
      '/credentials',
      '/workspaces',
      '/course/python-hello-001',
      '/lab/python-hello-001'
    ]) {
      for (final s in const [
        Size(1440, 900),
        Size(1280, 800),
        Size(1100, 700),
        Size(800, 600)
      ]) {
        await pumpAt(tester, s, location: loc);
        final e = tester.takeException();
        if (e != null) fail('overflow at $loc $s: $e');
      }
    }
  });

  testWidgets(
      'TC-DES-003-07 on a narrow window the side column moves under the main one instead of disappearing',
      (tester) async {
    await pumpAt(tester, const Size(1000, 700));
    expect(tester.getSize(find.byKey(const Key('sidebar'))).width, 104);
    expect(find.byKey(const Key('page-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('weekly-card')), findsOneWidget);
  });

  testWidgets(
      'TC-DES-003-08 selecting a sidebar item navigates and marks it selected',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const Key('nav-catalog')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-catalog')), findsOneWidget);
    final pill =
        tester.widget<AnimatedContainer>(find.byKey(const Key('pill-catalog')));
    expect((pill.decoration as BoxDecoration).color, BL.primarySoft);
  });

  testWidgets(
      'TC-DES-003-09 opening a lab row shows the course page with its facts, Start and a progress bar',
      (tester) async {
    await pumpAt(tester, const Size(1440, 1400));
    await tester.tap(find.byKey(const Key('activity-0')));
    await tester.pumpAndSettle();
    final header = find.byKey(const Key('course-header'));
    expect(header, findsOneWidget);
    expect(find.descendant(of: header, matching: find.text('Start')),
        findsOneWidget);
    expect(find.descendant(of: header, matching: find.byType(AsciiBar)),
        findsOneWidget);
    expect(find.byKey(const Key('chip-0')), findsOneWidget);
  });

  testWidgets(
      'TC-DES-003-13 Ctrl+K opens the command palette; typing filters labs and pages; Enter opens the first hit',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('palette')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('palette-input')), 'open-source');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('palette-hit-_course_oss-first-contribution-001')),
        findsOneWidget);
    expect(find.byKey(const Key('palette-hit-_course_python-hello-001')),
        findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('palette')), findsNothing);
    expect(find.byKey(const Key('course-header')), findsOneWidget);
  });

  testWidgets('TC-DES-003-14 Ctrl+number jumps between pages', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-paths')), findsOneWidget);
  });

  testWidgets(
      'TC-DES-003-15 the status bar shows the service and VS Code state in words, never a made-up value',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    final bar = find.byKey(const Key('statusbar'));
    expect(find.descendant(of: bar, matching: find.text('offline')),
        findsOneWidget,
        reason: 'the test app has no service');
    expect(find.descendant(of: bar, matching: find.text('not found')),
        findsOneWidget,
        reason: 'the mock worker found no editor');
    expect(
        find.descendant(
            of: bar, matching: find.byKey(const Key('status-week'))),
        findsOneWidget);
  });

  testWidgets(
      'TC-DES-003-10 lab page has breadcrumb, Practice score pill, Open VS Code again and the lab-folder panel; it never claims a badge',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900),
        location: '/lab/python-hello-001');
    expect(find.byKey(const Key('breadcrumb')), findsOneWidget);
    final bar = find.byKey(const Key('lab-toolbar'));
    expect(
        find.descendant(
            of: bar, matching: find.textContaining('Practice score')),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('Open VS Code again')),
        findsOneWidget);
    expect(find.text('Lab setup and access'), findsOneWidget);
    expect(find.textContaining('Only Verified results earn badges'),
        findsOneWidget);
    expect(find.textContaining('Badge earned'), findsNothing);
  });

  testWidgets(
      'TC-DES-003-11 the dashboard says progress belongs to the account, and the lab setup values are marked as samples',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(find.textContaining('saved for your account only'), findsOneWidget);
    expect(find.textContaining('Sample data'), findsNothing,
        reason: 'the dashboard no longer shows invented progress');
    await pumpAt(tester, const Size(1440, 900),
        location: '/course/python-hello-001');
    expect(find.textContaining('Sample data'), findsWidgets);
  });

  testWidgets(
      'TC-DES-003-12 backward navigation buttons exist across shell, course, lab, and placeholders',
      (tester) async {
    await pumpAt(tester, const Size(1440, 900), location: '/dashboard');
    expect(find.byKey(const Key('shell_back_button')), findsOneWidget);

    await pumpAt(tester, const Size(1440, 900),
        location: '/course/python-hello-001');
    expect(find.byKey(const Key('course_back_button')), findsOneWidget);

    await pumpAt(tester, const Size(1440, 900),
        location: '/lab/python-hello-001');
    expect(find.byKey(const Key('lab_back_button')), findsOneWidget);

    await pumpAt(tester, const Size(1440, 900), location: '/catalog');
    expect(find.byKey(const Key('shell_back_button')), findsOneWidget);
    expect(find.byKey(const Key('page-catalog')), findsOneWidget);
    expect(find.byKey(const Key('signed-out-notice')), findsOneWidget,
        reason:
            'the catalog is a real page that asks you to sign in, not a placeholder');
  });
}
