// Capability: CAP-DESIGN-SYSTEM. Tests: TC-MOT-01..06
// Implemented here: the motion kit starts hidden or empty, ends at the right value, lifts on hover, and does
// nothing at all when the system asks for reduced motion.
import 'package:desktop/ui/motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: child)),
      ),
    );

double opacityOf(WidgetTester t) => t
    .widget<Opacity>(find.descendant(
        of: find.byType(Reveal), matching: find.byType(Opacity)))
    .opacity;

void main() {
  testWidgets('TC-MOT-01 Reveal starts transparent and ends fully visible',
      (tester) async {
    await tester.pumpWidget(host(const Reveal(child: Text('hello'))));
    expect(opacityOf(tester), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('TC-MOT-02 a later item in a list starts later than the first',
      (tester) async {
    await tester.pumpWidget(
        host(const Column(mainAxisSize: MainAxisSize.min, children: [
      Reveal(index: 0, child: Text('first')),
      Reveal(index: 6, child: Text('seventh')),
    ])));
    await tester.pump(const Duration(milliseconds: 150));
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((o) => o.opacity)
        .toList();
    expect(opacities[0], greaterThan(opacities[1]));
    await tester.pumpAndSettle();
  });

  testWidgets('TC-MOT-03 with reduced motion nothing is animated or hidden',
      (tester) async {
    await tester
        .pumpWidget(host(const Reveal(child: Text('hello')), reduce: true));
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('hello'), findsOneWidget);
    await tester.pumpWidget(host(const CountUp(value: 7), reduce: true));
    expect(find.text('7'), findsOneWidget,
        reason: 'no counting up, straight to the value');
  });

  testWidgets('TC-MOT-04 CountUp counts from 0 to its value', (tester) async {
    await tester.pumpWidget(host(const CountUp(value: 12, suffix: '%')));
    expect(find.text('0%'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('12%'), findsOneWidget);
  });

  testWidgets(
      'TC-MOT-05 AnimatedBar fills to its value and glides to a new one',
      (tester) async {
    Widget bar(double v) => host(SizedBox(
        width: 200, child: AnimatedBar(barKey: const Key('b'), value: v)));
    await tester.pumpWidget(bar(0.5));
    expect(
        tester
            .widget<LinearProgressIndicator>(find.byKey(const Key('b')))
            .value,
        0);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<LinearProgressIndicator>(find.byKey(const Key('b')))
            .value,
        0.5);
    await tester.pumpWidget(bar(1.5)); // out of range is clamped
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<LinearProgressIndicator>(find.byKey(const Key('b')))
            .value,
        1);
  });

  testWidgets(
      'TC-MOT-06 HoverLift raises its child under the pointer and puts it back',
      (tester) async {
    await tester.pumpWidget(host(const HoverLift(
        child: SizedBox(width: 100, height: 60, child: Text('card')))));
    final rest = tester.getTopLeft(find.text('card')).dy;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('card')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('card')).dy, lessThan(rest));
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('card')).dy, rest);
  });
}
