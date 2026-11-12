// Capability: CAP-DESIGN-SYSTEM. Tests: TC-THEME-01..06
// Implemented here: light and dark both exist, the switch works and is remembered, a damaged preference means light,
// and the text colours are readable (WCAG AA contrast) on their surfaces in both themes.
import 'dart:io';
import 'dart:math' as math;
import 'package:desktop/api.dart';
import 'package:desktop/app.dart';
import 'package:desktop/data/app_prefs.dart';
import 'package:desktop/features/auth/auth_session.dart';
import 'package:desktop/router.dart';
import 'package:desktop/worker/worker_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

double luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() => BL.dark = false);

  for (final dark in [false, true]) {
    test(
        'TC-THEME-01 text colours are readable on their surfaces (${dark ? 'dark' : 'light'}): contrast at least 4.5',
        () {
      BL.dark = dark;
      final surfaces = {'surface': BL.surface, 'background': BL.background};
      final text = {
        'textPrimary': BL.textPrimary,
        'textSecondary': BL.textSecondary,
        'primary': BL.primary,
        'success': BL.success,
        'warning': BL.warning,
        'danger': BL.danger,
      };
      for (final s in surfaces.entries) {
        for (final t in text.entries) {
          expect(contrast(t.value, s.value), greaterThanOrEqualTo(4.5),
              reason: '${t.key} on ${s.key} (${dark ? 'dark' : 'light'})');
        }
      }
      expect(contrast(BL.onPrimary, BL.primary), greaterThanOrEqualTo(4.5),
          reason: 'button text on the primary colour');
      expect(contrast(Colors.white, BL.heroStart), greaterThanOrEqualTo(7),
          reason: 'white text on the continue card');
    });
  }

  test(
      'TC-THEME-02 the two palettes are really different and the getters follow the switch',
      () {
    BL.dark = false;
    final lightBg = BL.background;
    final lightPrimary = BL.primary;
    BL.dark = true;
    expect(BL.background, isNot(lightBg));
    expect(BL.primary, isNot(lightPrimary));
    expect(luminance(BL.background), lessThan(0.05), reason: 'dark is dark');
    BL.dark = false;
    expect(luminance(BL.background), greaterThan(0.8),
        reason: 'light is light');
  });

  test(
      'TC-THEME-03 the preference round-trips, and a missing or damaged file means light',
      () async {
    final dir = Directory.systemTemp.createTempSync('devpilot-prefs-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final prefs = AppPrefs(dir.path);
    expect(prefs.loadDark(), isFalse, reason: 'no file yet');
    await prefs.saveDark(true);
    expect(prefs.loadDark(), isTrue);
    await prefs.saveDark(false);
    expect(prefs.loadDark(), isFalse);
    File('${dir.path}/prefs.json').writeAsStringSync('{ not json');
    expect(prefs.loadDark(), isFalse);
    File('${dir.path}/prefs.json')
        .writeAsStringSync('{"theme": ${"x" * 10000}}');
    expect(prefs.loadDark(), isFalse, reason: 'an oversize file is ignored');
  });

  testWidgets(
      'TC-THEME-04 the switch in the header flips the whole app between light and dark and saves the choice',
      (tester) async {
    final saved = <bool>[];
    AuthSession.instance.signOut();
    AuthSession.instance.signIn(
        const AuthUser(uid: 'u', email: 'a@example.com', displayName: 'Asha'));
    addTearDown(AuthSession.instance.signOut);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        workerClientProvider.overrideWithValue(MockWorkerClient()),
        themeDarkProvider.overrideWith(
            (ref) => ThemeModeController(false, (d) async => saved.add(d))),
      ],
      child: DevPilotApp(router: createRouter(initialLocation: '/dashboard')),
    ));
    await tester.pumpAndSettle();
    Color scaffold() =>
        Theme.of(tester.element(find.byKey(const Key('topbar'))))
            .scaffoldBackgroundColor;
    final light = scaffold();
    expect(BL.dark, isFalse);
    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(BL.dark, isTrue);
    expect(scaffold(), isNot(light));
    expect(find.byKey(const Key('page-dashboard')), findsOneWidget,
        reason: 'the page stays where it was');
    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(BL.dark, isFalse);
    expect(scaffold(), light);
    expect(saved, [true, false], reason: 'each switch is saved');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TC-THEME-05 every main page draws without errors in dark as well',
      (tester) async {
    for (final loc in [
      '/dashboard',
      '/catalog',
      '/paths',
      '/credentials',
      '/workspaces',
      '/course/python-hello-001',
      '/lab/python-hello-001',
      '/landing'
    ]) {
      AuthSession.instance.signOut();
      AuthSession.instance.signIn(const AuthUser(
          uid: 'u', email: 'a@example.com', displayName: 'Asha'));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          workerClientProvider.overrideWithValue(MockWorkerClient()),
          themeDarkProvider
              .overrideWith((ref) => ThemeModeController(true, (_) async {})),
        ],
        child: DevPilotApp(router: createRouter(initialLocation: loc)),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: loc);
    }
    addTearDown(AuthSession.instance.signOut);
    addTearDown(tester.view.reset);
  });
}
