// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-USE-001
// Test ID: TC-DES-003-01..11
// Implemented here: BuildLoop shell in the Google-Skills style (header, icon rail), dashboard, course page, lab page

import 'package:desktop/app.dart';
import 'package:desktop/router.dart';
import 'package:desktop/api.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAt(WidgetTester tester, Size size, {String location = '/dashboard'}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [workerClientProvider.overrideWithValue(MockWorkerClient())],
    child: BuildLoopApp(router: createRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-DES-003-01 header is 64px and the icon rail is 104px at 1440x900', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(tester.getSize(find.byKey(const Key('topbar'))).height, 64);
    expect(tester.getSize(find.byKey(const Key('rail'))).width, 104);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-DES-003-02 rail lists the five sections in order, icon above label', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    const labels = ['Dashboard', 'Catalog', 'Paths', 'Credentials', 'Workspaces'];
    final ys = <double>[];
    for (final l in labels) {
      final f = find.descendant(of: find.byKey(const Key('rail')), matching: find.text(l));
      expect(f, findsOneWidget, reason: l);
      ys.add(tester.getTopLeft(f).dy);
    }
    expect(ys, orderedEquals([...ys]..sort()));
    final icon = tester.getCenter(find.descendant(of: find.byKey(const Key('nav-catalog')), matching: find.byType(Icon)));
    final label = tester.getCenter(find.descendant(of: find.byKey(const Key('nav-catalog')), matching: find.text('Catalog')));
    expect(icon.dy, lessThan(label.dy));
  });

  testWidgets('TC-DES-003-03 header has menu, wordmark, pill search, streak, help and profile', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    final bar = find.byKey(const Key('topbar'));
    expect(find.descendant(of: bar, matching: find.byIcon(Icons.menu)), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('BuildLoop')), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byType(TextField)), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byKey(const Key('streak'))), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byIcon(Icons.help_outline)), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.byKey(const Key('profile'))), findsOneWidget);
  });

  testWidgets('TC-DES-003-04 dashboard has hero, tabs and a grid of activity cards', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(find.descendant(of: find.byKey(const Key('hero')), matching: find.text('Resume')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('tabs')), matching: find.text('Activities')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('tabs')), matching: find.text('Paths')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('activity-$i')), findsOneWidget, reason: 'card $i');
    }
    expect(find.text('Featured'), findsWidgets);
  });

  testWidgets('TC-DES-003-05 right column has badges, skills, weekly goal and achievements', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    for (final k in ['badges-card', 'skills-card', 'weekly-card', 'achievements']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('day-$i')), findsOneWidget, reason: 'day $i');
    }
  });

  testWidgets('TC-DES-003-06 no overflow at 1440x900, 1280x800, 1100x700 and 800x600', (tester) async {
    for (final loc in ['/dashboard', '/course/python-hello-001', '/lab/python-hello-001']) {
      for (final s in const [Size(1440, 900), Size(1280, 800), Size(1100, 700), Size(800, 600)]) {
        await pumpAt(tester, s, location: loc);
        expect(tester.takeException(), isNull, reason: '$loc $s');
      }
    }
  });

  testWidgets('TC-DES-003-07 right column is hidden on narrow windows', (tester) async {
    await pumpAt(tester, const Size(1000, 700));
    expect(find.byKey(const Key('weekly-card')), findsNothing);
  });

  testWidgets('TC-DES-003-08 selecting a rail item navigates and highlights the icon pill', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    await tester.tap(find.descendant(of: find.byKey(const Key('rail')), matching: find.text('Catalog')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-catalog')), findsOneWidget);
    final pill = tester.widget<AnimatedContainer>(find.byKey(const Key('pill-catalog')));
    expect((pill.decoration as BoxDecoration).color, const Color(0xFFEAF1FF));
  });

  testWidgets('TC-DES-003-09 opening an activity shows the course page with a dark header, chips, Start and progress', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const Key('activity-0')));
    await tester.pumpAndSettle();
    final header = find.byKey(const Key('course-header'));
    expect(header, findsOneWidget);
    expect((tester.widget<Container>(header).decoration as BoxDecoration).color, const Color(0xFF183153));
    expect(find.descendant(of: header, matching: find.text('Start')), findsOneWidget);
    expect(find.descendant(of: header, matching: find.byType(LinearProgressIndicator)), findsOneWidget);
    expect(find.byKey(const Key('chip-0')), findsOneWidget);
  });

  testWidgets('TC-DES-003-10 lab page has breadcrumb, Practice score pill, Open VS Code again and the lab-folder panel; it never claims a badge', (tester) async {
    await pumpAt(tester, const Size(1440, 900), location: '/lab/python-hello-001');
    expect(find.byKey(const Key('breadcrumb')), findsOneWidget);
    final bar = find.byKey(const Key('lab-toolbar'));
    expect(find.descendant(of: bar, matching: find.textContaining('Practice score')), findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('Open VS Code again')), findsOneWidget);
    expect(find.text('Lab setup and access'), findsOneWidget);
    expect(find.textContaining('Only Verified results earn badges'), findsOneWidget);
    expect(find.textContaining('Badge earned'), findsNothing);
  });

  testWidgets('TC-DES-003-11 sample data is labelled on the dashboard and the lab setup values are marked as samples', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(find.textContaining('Sample data'), findsWidgets);
    await pumpAt(tester, const Size(1440, 900), location: '/course/python-hello-001');
    expect(find.textContaining('Sample data'), findsWidgets);
  });
}
