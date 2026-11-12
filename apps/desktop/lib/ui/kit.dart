// Capability: CAP-DESIGN-SYSTEM. Tests: TC-KIT-01..
// Implemented here: the building blocks of the DevPilot look (docs/DESIGN_SYSTEM.md): cards that rest on the canvas with a
// soft shadow, tinted icon tiles, soft status chips, progress bars and rings, a week chart, a heatmap and a timeline.
// Screens compose these instead of styling their own. Every colour comes from BL, so light and dark both work.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'motion.dart';

enum Tone { accent, muted, warn, bad, info, plain }

Color toneColor(Tone t) => switch (t) {
      Tone.accent => BL.success,
      Tone.muted => BL.textSecondary,
      Tone.warn => BL.warning,
      Tone.bad => BL.danger,
      Tone.info => BL.primary,
      Tone.plain => BL.textPrimary,
    };

/// A small soft chip: a tinted background and text of the same hue. Used for every status and label.
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.tone = Tone.muted, this.dot = false});

  final String label;
  final Tone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: BL.dark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6)
        ],
        Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BL.mono(size: 11.5, color: c, weight: FontWeight.w600))),
      ]),
    );
  }
}

/// A hairline.
class Rule extends StatelessWidget {
  const Rule({super.key, this.vertical = false, this.strong = false});

  final bool vertical;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = strong ? BL.borderStrong : BL.border;
    return vertical
        ? Container(width: 1, color: c)
        : Container(height: 1, color: c);
  }
}

/// A heading for a group of content, with an optional action on the right.
class Section extends StatelessWidget {
  const Section(
      {super.key,
      required this.label,
      this.trailing,
      required this.child,
      this.gap = BL.space4});

  final String label;
  final Widget? trailing;
  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title =
        label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: text.titleLarge)),
          if (trailing != null) trailing!,
        ]),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

/// A white card with a hairline border and a soft shadow. Optional title, tap and hover lift.
class Panel extends StatelessWidget {
  const Panel(
      {super.key,
      required this.child,
      this.title,
      this.padding = const EdgeInsets.all(BL.space6),
      this.onTap,
      this.accent = false,
      this.trailing,
      this.lift = false});

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool accent;
  final Widget? trailing;
  final bool lift;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(BL.radiusCard);
    final text = Theme.of(context).textTheme;
    Widget card = Container(
      decoration: BoxDecoration(
          color: BL.surface,
          borderRadius: radius,
          border: Border.all(
              color: accent ? BL.primary.withValues(alpha: 0.45) : BL.border),
          boxShadow: BL.shadowCard),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: onTap == null
              ? Colors.transparent
              : BL.primary.withValues(alpha: 0.03),
          highlightColor: Colors.transparent,
          splashColor: BL.primary.withValues(alpha: 0.05),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        BL.space6, BL.space4, BL.space6, BL.space3),
                    child: Row(children: [
                      Expanded(child: Text(title!, style: text.titleSmall)),
                      if (trailing != null) trailing!,
                    ]),
                  ),
                  const Rule(),
                ],
                Padding(padding: padding, child: child),
              ]),
        ),
      ),
    );
    if (lift) card = HoverLift(radius: BL.radiusCard, lift: 2, child: card);
    return card;
  }
}

/// A rounded square with an icon on a pale tint.
class IconTile extends StatelessWidget {
  const IconTile(
      {super.key, required this.icon, this.tint, this.color, this.size = 40});

  final IconData icon;
  final Color? tint;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: tint ?? BL.tintBlue,
            borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, color: color ?? BL.blue, size: size * 0.5),
      );
}

/// Icon and colours for a kind of activity, so every list and card tells them apart the same way.
({IconData icon, Color tint, Color color}) activityVisual(List<String> kinds) {
  if (kinds.contains('AI-generated'))
    return (icon: Icons.auto_awesome, tint: BL.tintAmber, color: BL.amber);
  if (kinds.contains('Path'))
    return (icon: Icons.route, tint: BL.tintTeal, color: BL.teal);
  if (kinds.contains('Course'))
    return (icon: Icons.menu_book, tint: BL.tintViolet, color: BL.violet);
  return (icon: Icons.terminal, tint: BL.tintBlue, color: BL.blue);
}

/// A key hint such as "Ctrl K".
class Kbd extends StatelessWidget {
  const Kbd(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
            color: BL.surface,
            border: Border.all(color: BL.border),
            borderRadius: BorderRadius.circular(5)),
        child: Text(label, style: BL.mono(size: 10.5, weight: FontWeight.w600)),
      );
}

/// A rounded progress bar that fills the first time it appears and glides when the value changes. Fills the width it is
/// given (160px when the width is unbounded). `cells` and `size` are accepted for older callers and ignored.
class AsciiBar extends StatelessWidget {
  const AsciiBar(
      {super.key,
      required this.value,
      this.cells = 24,
      this.size = 13,
      this.color,
      this.height = 8});

  final double value;
  final int cells;
  final double size;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    Widget bar(double t) => LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 160.0;
          return SizedBox(
            width: w,
            height: height,
            child: Stack(children: [
              Container(
                  decoration: BoxDecoration(
                      color: BL.surfaceMuted,
                      borderRadius: BorderRadius.circular(height))),
              Container(
                  width: w * t,
                  decoration: BoxDecoration(
                      color: color ?? BL.primary,
                      borderRadius: BorderRadius.circular(height))),
            ]),
          );
        });
    if (reducedMotion(context)) return bar(v);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => bar(t),
    );
  }
}

/// A circular progress ring with a child in the middle. It fills the first time it appears.
class ProgressRing extends StatelessWidget {
  const ProgressRing(
      {super.key,
      required this.value,
      this.size = 96,
      this.stroke = 9,
      this.color,
      this.track,
      this.child});

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    Widget ring(double t) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
              t, stroke, color ?? BL.primary, track ?? BL.surfaceMuted),
          child:
              SizedBox(width: size, height: size, child: Center(child: child)),
        );
    if (reducedMotion(context)) return ring(v);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ring(t),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    Paint p(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;
    canvas.drawArc(rect, 0, math.pi * 2, false, p(track));
    if (value > 0)
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p(color));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}

/// Seven small bars, one per day, the last one (today) in the brand colour.
class WeekBars extends StatelessWidget {
  const WeekBars(
      {super.key,
      required this.values,
      required this.labels,
      this.height = 72,
      this.keyPrefix = 'bar'});

  final List<int> values;
  final List<String> labels;
  final double height;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (m, v) => v > m ? v : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: height,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _Bar(
                    key: Key('$keyPrefix-$i'),
                    fraction:
                        values[i] == 0 ? 0.08 : (0.25 + 0.75 * values[i] / max),
                    color: values[i] == 0
                        ? BL.surfaceMuted
                        : (i == values.length - 1
                            ? BL.primary
                            : BL.primary.withValues(alpha: 0.45)),
                    height: height,
                  ),
                ),
              ),
              const SizedBox(height: BL.space2),
              Text(labels[i],
                  style: BL.mono(
                      size: 11,
                      color: i == values.length - 1
                          ? BL.textPrimary
                          : BL.textSecondary,
                      weight: i == values.length - 1
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ]),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {super.key,
      required this.fraction,
      required this.color,
      required this.height});

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget bar(double f) => Container(
        width: 16,
        height: height * f,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)));
    if (reducedMotion(context)) return bar(fraction);
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, f, _) => bar(f));
  }
}

/// Contribution heatmap: columns are weeks, rows are days. [counts] is oldest first and ends today.
class Heatmap extends StatelessWidget {
  const Heatmap(
      {super.key,
      required this.counts,
      this.cell = 12,
      this.gap = 3,
      this.endWeekday = 1,
      this.fill = false});

  final List<int> counts;
  final double cell;
  final double gap;
  final int endWeekday;
  final bool fill;

  Color _color(int n) {
    if (n <= 0) return BL.surfaceMuted;
    if (n == 1) return BL.primary.withValues(alpha: 0.35);
    if (n == 2) return BL.primary.withValues(alpha: 0.65);
    return BL.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (!fill) return _grid(cell);
    return LayoutBuilder(builder: (context, box) {
      final lead = ((endWeekday - 1) - (counts.length - 1)) % 7;
      final weeks = ((counts.length + lead) / 7).ceil();
      return _grid(
          ((box.maxWidth - gap * (weeks - 1)) / weeks).clamp(9.0, 18.0));
    });
  }

  Widget _grid(double cell) {
    final lead = ((endWeekday - 1) - (counts.length - 1)) % 7;
    final cells = [for (var i = 0; i < lead; i++) -1, ...counts];
    final weeks = (cells.length / 7).ceil();
    return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = 0; w < weeks; w++)
            Padding(
              padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
              child: Column(children: [
                for (var d = 0; d < 7; d++)
                  Padding(
                    padding: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
                    child: () {
                      final i = w * 7 + d;
                      final n = i < cells.length ? cells[i] : -1;
                      return Container(
                          key: n >= 0 ? Key('heat-${i - lead}') : null,
                          width: cell,
                          height: cell,
                          decoration: BoxDecoration(
                              color: n < 0 ? Colors.transparent : _color(n),
                              borderRadius: BorderRadius.circular(3)));
                    }(),
                  ),
              ]),
            ),
        ]);
  }
}

enum NodeState { done, head, todo, later }

/// One step in a vertical timeline: a node on a line, with content to the right.
class GitNode extends StatelessWidget {
  const GitNode(
      {super.key,
      required this.state,
      required this.child,
      this.first = false,
      this.last = false});

  final NodeState state;
  final Widget child;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            width: 28,
            child: CustomPaint(
                painter: _GraphPainter(
                    state,
                    first,
                    last,
                    BL.primary,
                    BL.borderStrong,
                    BL.border,
                    BL.surface,
                    BL.textDisabled,
                    BL.textSecondary,
                    BL.success))),
        Expanded(
            child: Padding(
                padding:
                    const EdgeInsets.only(bottom: BL.space4, left: BL.space2),
                child: child)),
      ]),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.state, this.first, this.last, this.primary, this.line,
      this.faint, this.bg, this.disabled, this.secondary, this.success);

  final NodeState state;
  final bool first;
  final bool last;
  final Color primary;
  final Color line;
  final Color faint;
  final Color bg;
  final Color disabled;
  final Color secondary;
  final Color success;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 10.0;
    const nodeY = 10.0;
    final l = Paint()
      ..color = state == NodeState.later ? faint : line
      ..strokeWidth = 2;
    if (!first)
      canvas.drawLine(const Offset(x, 0), const Offset(x, nodeY - 7), l);
    if (!last)
      canvas.drawLine(const Offset(x, nodeY + 7), Offset(x, size.height), l);
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    switch (state) {
      case NodeState.done:
        canvas.drawCircle(const Offset(x, nodeY), 7, fill(success));
        final tick = Path()
          ..moveTo(x - 3, nodeY)
          ..lineTo(x - 0.5, nodeY + 2.5)
          ..lineTo(x + 3.5, nodeY - 2.5);
        canvas.drawPath(
            tick,
            stroke(Colors.white, 1.8)
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
      case NodeState.head:
        canvas.drawCircle(
            const Offset(x, nodeY), 10, fill(primary.withValues(alpha: 0.16)));
        canvas.drawCircle(const Offset(x, nodeY), 6, fill(primary));
      case NodeState.todo:
        canvas.drawCircle(const Offset(x, nodeY), 6, fill(bg));
        canvas.drawCircle(const Offset(x, nodeY), 6, stroke(secondary, 2));
      case NodeState.later:
        canvas.drawCircle(const Offset(x, nodeY), 5.5, fill(bg));
        canvas.drawCircle(const Offset(x, nodeY), 5.5, stroke(disabled, 1.5));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.state != state ||
      old.first != first ||
      old.last != last ||
      old.primary != primary ||
      old.bg != bg ||
      old.line != line;
}

/// A heading for a page: a small eyebrow, a large title, and an optional line of description.
class PageHead extends StatelessWidget {
  const PageHead(
      {super.key,
      required this.label,
      required this.title,
      this.description,
      this.trailing});

  final String label;
  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final eyebrow = label.replaceFirst('~/', '').replaceAll('/', '  /  ');
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(),
              style: BL.mono(
                  size: 11.5,
                  color: BL.primary,
                  spacing: 1.4,
                  weight: FontWeight.w700)),
          const SizedBox(height: BL.space2),
          Text(title, style: text.headlineMedium),
          if (description != null) ...[
            const SizedBox(height: BL.space2),
            Text(description!,
                style: text.bodyMedium?.copyWith(color: BL.textSecondary))
          ],
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

/// A row of pill-shaped tabs inside a soft track. The selected one is a raised white pill.
class PillTabs extends StatelessWidget {
  const PillTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged,
      this.itemKey,
      this.enabled = true});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Key Function(String label)? itemKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: BL.surfaceMuted, borderRadius: BorderRadius.circular(22)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < labels.length; i++)
          InkWell(
            key: itemKey?.call(labels[i]),
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? () => onChanged(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: i == selected ? BL.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: i == selected
                    ? [
                        BoxShadow(
                            color: BL.p.shadow
                                .withValues(alpha: BL.dark ? 0.0 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1))
                      ]
                    : null,
                border: i == selected && BL.dark
                    ? Border.all(color: BL.borderStrong)
                    : null,
              ),
              child: Text(labels[i],
                  style: BL.mono(
                      size: 13,
                      color: i == selected ? BL.primary : BL.textSecondary,
                      weight:
                          i == selected ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
      ]),
    );
  }
}
