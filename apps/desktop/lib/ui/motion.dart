// Capability: CAP-DESIGN-SYSTEM. Tests: TC-MOT-01..
// Implemented here: the small motion kit used across the app. Every piece is one-shot (nothing loops, so tests
// and battery are not affected), is short (under 600 ms), and turns itself off when the system asks for
// reduced motion (MediaQuery.disableAnimations).

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

bool reducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Fades and slides its child up the first time it appears. [index] staggers a row or grid of items.
class Reveal extends StatelessWidget {
  const Reveal(
      {super.key, required this.child, this.index = 0, this.offset = 14});

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return child;
    final step = index.clamp(0, 9);
    final delay = 55 * step;
    final total = 380 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, (1 - t) * offset), child: child),
      ),
    );
  }
}

/// Lifts a card a few pixels and softens its shadow while the pointer is over it.
class HoverLift extends StatefulWidget {
  const HoverLift(
      {super.key,
      required this.child,
      this.radius = BL.radiusXl,
      this.lift = 3});

  final Widget child;
  final double radius;
  final double lift;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = _hover && !reducedMotion(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, on ? -widget.lift : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF183153).withValues(alpha: on ? 0.14 : 0),
              blurRadius: on ? 22 : 0,
              offset: Offset(0, on ? 10 : 0),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// A whole number that counts up to its value the first time it appears, then follows changes.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style, this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v$suffix', style: style),
    );
  }
}

/// A progress bar that fills smoothly to its value and glides when the value changes.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar(
      {super.key,
      required this.value,
      this.color,
      this.backgroundColor,
      this.minHeight,
      this.barKey});

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double? minHeight;
  final Key? barKey;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    if (reducedMotion(context)) {
      return LinearProgressIndicator(
          key: barKey,
          value: v,
          color: color,
          backgroundColor: backgroundColor,
          minHeight: minHeight);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => LinearProgressIndicator(
          key: barKey,
          value: t,
          color: color,
          backgroundColor: backgroundColor,
          minHeight: minHeight),
    );
  }
}
