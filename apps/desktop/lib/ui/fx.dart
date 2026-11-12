// Capability: CAP-DESIGN-SYSTEM. Tests: TC-FX-01..
// Implemented here: the visual effects kit. Everything is drawn in code (no downloaded art) and respects the same rule
// as motion.dart: nothing animates in tests or when the system asks for reduced motion, and each effect is cheap
// (one controller, one painter).
//  - AuroraBackdrop: a slowly moving mesh of coloured light, for hero areas.
//  - TiltCard: a card that tilts in 3D towards the pointer with a moving glare and a deeper shadow.
//  - GlowFrame: a light that travels around a card's border (the prompt box).
//  - IsoStack: a floating isometric stack of glass layers, the hero illustration.
//  - Confetti: a one-shot celebration burst.
//  - ShimmerBox: a loading placeholder with a moving highlight.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'motion.dart';

/// Tests set this to run the real animations once.
bool debugFxForceOn = false;

/// True when animated effects may run: not in tests and not with reduced motion.
bool fxOn(BuildContext context) =>
    !reducedMotion(context) &&
    (debugFxForceOn ||
        !WidgetsBinding.instance.runtimeType.toString().contains('Test'));

/// A looping 0..1 clock that only runs when effects are on.
mixin _Loop<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController clock;

  Duration get period;

  @override
  void initState() {
    super.initState();
    clock = AnimationController(vsync: this, duration: period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (fxOn(context)) {
      if (!clock.isAnimating) clock.repeat();
    } else {
      clock.stop();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }
}

// ------------------------------------------------------------------------------------------------ aurora

class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop(
      {super.key, required this.child, this.radius = BL.radiusXl, this.colors});

  final Widget child;
  final double radius;

  /// Blob colours. Defaults to the brand blues with a violet and a teal accent.
  final List<Color>? colors;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with TickerProviderStateMixin, _Loop {
  @override
  Duration get period => const Duration(seconds: 22);

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [const Color(0xFF5B8CFF), BL.violet, BL.teal, const Color(0xFF2459E6)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: clock,
              builder: (_, __) =>
                  CustomPaint(painter: _AuroraPainter(clock.value, colors)),
            ),
          ),
        ),
        widget.child,
      ]),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t, this.colors);
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BL.heroStart, BL.heroEnd]).createShader(rect),
    );
    final base = math.max(size.width, size.height);
    for (var i = 0; i < colors.length; i++) {
      final a = (t + i / colors.length) * 2 * math.pi;
      final c = Offset(
        size.width * (0.5 + 0.42 * math.sin(a * (1 + i * 0.35) + i)),
        size.height * (0.5 + 0.42 * math.cos(a * (0.8 + i * 0.25) + i * 1.7)),
      );
      final r = base * (0.42 + 0.08 * math.sin(a + i));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            colors[i].withValues(alpha: 0.5),
            colors[i].withValues(alpha: 0)
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    // fine dots for texture
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var x = 18.0; x < size.width; x += 26) {
      for (var y = 18.0; y < size.height; y += 26) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.colors != colors;
}

// ------------------------------------------------------------------------------------------------ tilt card

class TiltCard extends StatefulWidget {
  const TiltCard(
      {super.key,
      required this.child,
      this.radius = BL.radiusCard,
      this.maxTilt = 0.055});

  final Widget child;
  final double radius;
  final double maxTilt;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _p = Offset.zero; // -1..1 from the card's centre
  bool _hover = false;

  void _move(PointerEvent e, Size size) {
    if (size.isEmpty) return;
    setState(() {
      _hover = true;
      _p = Offset((e.localPosition.dx / size.width) * 2 - 1,
          (e.localPosition.dy / size.height) * 2 - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!fxOn(context))
      return HoverLift(radius: widget.radius, child: widget.child);
    return LayoutBuilder(builder: (context, box) {
      final size =
          Size(box.maxWidth, box.maxHeight.isFinite ? box.maxHeight : 200);
      return MouseRegion(
        onEnter: (e) => _move(e, size),
        onHover: (e) => _move(e, size),
        onExit: (_) => setState(() {
          _hover = false;
          _p = Offset.zero;
        }),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _p),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          builder: (context, p, child) {
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(-p.dy * widget.maxTilt)
              ..rotateY(p.dx * widget.maxTilt)
              ..scale(_hover ? 1.012 : 1.0);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  boxShadow: _hover
                      ? [
                          BoxShadow(
                              color: BL.primary.withValues(alpha: 0.18),
                              blurRadius: 30,
                              spreadRadius: -4,
                              offset: Offset(-p.dx * 10, 14 - p.dy * 6)),
                        ]
                      : const [],
                ),
                child: Stack(children: [
                  child!,
                  if (_hover)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.radius),
                            gradient: RadialGradient(
                              center: Alignment(p.dx, p.dy),
                              radius: 0.9,
                              colors: [
                                (BL.dark ? Colors.white : BL.primary)
                                    .withValues(alpha: BL.dark ? 0.07 : 0.07),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          },
          child: widget.child,
        ),
      );
    });
  }
}

// ------------------------------------------------------------------------------------------------ glow frame

class GlowFrame extends StatefulWidget {
  const GlowFrame(
      {super.key, required this.child, this.radius = BL.radiusCard});

  final Widget child;
  final double radius;

  @override
  State<GlowFrame> createState() => _GlowFrameState();
}

class _GlowFrameState extends State<GlowFrame>
    with TickerProviderStateMixin, _Loop {
  @override
  Duration get period => const Duration(seconds: 7);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      builder: (_, child) => CustomPaint(
        foregroundPainter:
            _GlowPainter(clock.value, widget.radius, fxOn(context)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t, this.radius, this.live);
  final double t;
  final double radius;
  final bool live;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5), Radius.circular(radius));
    final colors = [
      Colors.transparent,
      BL.primary,
      BL.violet,
      BL.teal,
      Colors.transparent
    ];
    final shader = SweepGradient(
      colors: colors,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(t * 2 * math.pi),
    ).createShader(Offset.zero & size);
    if (live) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
          ..color = Colors.white.withValues(alpha: 0.4),
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t || old.live != live;
}

// ------------------------------------------------------------------------------------------------ iso stack

class IsoStack extends StatefulWidget {
  const IsoStack({super.key, this.size = 250, this.icon = Icons.terminal});

  final double size;
  final IconData icon;

  @override
  State<IsoStack> createState() => _IsoStackState();
}

class _IsoStackState extends State<IsoStack>
    with TickerProviderStateMixin, _Loop {
  @override
  Duration get period => const Duration(seconds: 6);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: clock,
          builder: (_, __) => CustomPaint(painter: _IsoPainter(clock.value)),
        ),
      ),
    );
  }
}

class _IsoPainter extends CustomPainter {
  _IsoPainter(this.t);
  final double t;

  void _layer(Canvas canvas, Offset c, double w, double alpha,
      {bool top = false}) {
    // an isometric tile: a rounded square, rotated 45 degrees and squashed vertically
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, 0.56);
    canvas.rotate(math.pi / 4);
    final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: w),
        Radius.circular(w * 0.16));
    // thickness: a darker copy underneath
    canvas.drawRRect(
        rr.shift(const Offset(0, 0)),
        Paint()
          ..color = const Color(0xFF0B1B4D).withValues(alpha: 0.35 * alpha));
    final face = rr.shift(Offset(-3, -3));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.32 * alpha),
            Colors.white.withValues(alpha: 0.10 * alpha)
          ],
        ).createShader(face.outerRect),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.55 * alpha),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.70;
    final a = t * 2 * math.pi;
    // ground shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.9),
          width: size.width * 0.62,
          height: 22),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final w = size.width * 0.5;
    for (var i = 0; i < 3; i++) {
      final lift = i * size.height * 0.16 +
          math.sin(a + i * 0.9) * 5 +
          i * math.sin(a * 0.5) * 2;
      _layer(canvas, Offset(cx, cy - lift), w, 0.55 + i * 0.22, top: i == 2);
    }
    // glow under the top tile
    final gc = Offset(cx, cy - 2 * size.height * 0.16 - 4);
    canvas.drawCircle(
      gc,
      size.width * 0.32,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF7BE0B0).withValues(alpha: 0.28),
          Colors.transparent
        ]).createShader(Rect.fromCircle(center: gc, radius: size.width * 0.32)),
    );
    // floating sparks
    final spark = Paint();
    for (var i = 0; i < 7; i++) {
      final ang = a * 0.6 + i * 0.9;
      final p = Offset(
        cx + math.cos(ang) * size.width * (0.30 + 0.05 * (i % 3)),
        size.height * 0.34 + math.sin(ang * 1.3) * size.height * 0.2 - i * 3,
      );
      spark.color =
          Colors.white.withValues(alpha: 0.25 + 0.25 * ((i + 1) % 3) / 2);
      canvas.drawCircle(p, 2.2 + (i % 3), spark);
    }
  }

  @override
  bool shouldRepaint(_IsoPainter old) => old.t != t;
}

// ------------------------------------------------------------------------------------------------ confetti

class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && fxOn(context)) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => _c.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(painter: _ConfettiPainter(_c.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final colors = [
      BL.blue,
      BL.violet,
      BL.teal,
      BL.amber,
      BL.rose,
      const Color(0xFF7BE0B0)
    ];
    final origin = Offset(size.width * 0.5, size.height * 0.5);
    for (var i = 0; i < 70; i++) {
      final ang = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.4;
      final speed = 220 + rnd.nextDouble() * 360;
      final spin = rnd.nextDouble() * 10;
      final x = origin.dx + math.cos(ang) * speed * t * 1.2;
      final y = origin.dy + math.sin(ang) * speed * t + 520 * t * t; // gravity
      final fade = (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: 8,
                height: 4 + rnd.nextDouble() * 5),
            const Radius.circular(1.5)),
        Paint()..color = colors[i % colors.length].withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ------------------------------------------------------------------------------------------------ shimmer

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with TickerProviderStateMixin, _Loop {
  @override
  Duration get period => const Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + clock.value * 3, 0),
            end: Alignment(-0.5 + clock.value * 3, 0),
            colors: [BL.surfaceMuted, BL.border, BL.surfaceMuted],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------ pulse ring

/// A soft ring that expands and fades around [child], to mark "this is where you are".
class PulseRing extends StatefulWidget {
  const PulseRing(
      {super.key, required this.child, required this.color, this.size = 44});

  final Widget child;
  final Color color;
  final double size;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with TickerProviderStateMixin, _Loop {
  @override
  Duration get period => const Duration(milliseconds: 2200);

  @override
  Widget build(BuildContext context) {
    final big = widget.size * 1.9;
    return SizedBox(
      width: big,
      height: big,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: clock,
          builder: (_, __) {
            final live = fxOn(context);
            final t = live ? clock.value : 0.35;
            return Container(
              width: widget.size * (1 + 0.9 * t),
              height: widget.size * (1 + 0.9 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.28 * (1 - t)),
              ),
            );
          },
        ),
        widget.child,
      ]),
    );
  }
}
