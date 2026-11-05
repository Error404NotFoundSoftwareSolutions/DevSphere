import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One-shot rocket launch animation inside a glassmorphic card.
/// Features:
/// - Phase 1 (0.0 - 0.2): Ignition & rumble vibration (sin(time * 50) * 2.0)
/// - Phase 2 (0.2 - 1.0): Blast off upwards with Curves.easeInCubic
/// - Particle system: Glowing yellow-to-orange-to-cyan sparks & expanding smoke puffs
/// - Masking with ClipRRect(borderRadius: 24)
/// - Intense radial orange/cyan light bloom at the bottom during ignition
class LaunchingRocketCard extends StatefulWidget {
  final VoidCallback onLaunchComplete;
  final Widget? child;

  const LaunchingRocketCard({
    super.key,
    required this.onLaunchComplete,
    this.child,
  });

  @override
  State<LaunchingRocketCard> createState() => LaunchingRocketCardState();
}

class LaunchingRocketCardState extends State<LaunchingRocketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _shake;

  bool get isLaunching => _controller.isAnimating;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Rocket lifts off and accelerates upwards out of card viewport
    _translateY = Tween<double>(begin: 0.0, end: -650.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInCubic),
      ),
    );

    // Rumble / micro-vibration during Phase 1 ignition (0.0 - 0.25)
    _shake = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.linear),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLaunchComplete();
      }
    });
  }

  /// Call this when the Sign-in button is clicked
  void launch() {
    _controller.forward(from: 0.0);
  }

  /// Reset the rocket back to launchpad
  void reset() {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Phase 1 (0.0 - 0.2): Subtle micro-vibration/shake effect (sin(time * 50) * 2.0)
        final shakeOffset = (_shake.value > 0.0 && _shake.value < 1.0)
            ? math.sin(_controller.value * 50.0) * 2.0
            : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            children: [
              // Base Card Content (top bar, slideshow/copy, indicators)
              if (widget.child != null) widget.child!,

              // 1. Intense radial orange/cyan light bloom during ignition
              if (_controller.value > 0.02 && _controller.value < 0.7)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: IgnitionBloomPainter(progress: _controller.value),
                    ),
                  ),
                ),

              // 2. Rocket Body + Thruster Flame & Particle Trail
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _controller.isAnimating || _controller.isCompleted,
                  child: Transform.translate(
                    offset: Offset(shakeOffset, _translateY.value),
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!_controller.isAnimating && !_controller.isCompleted) {
                            launch();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/rocket.png',
                              key: const Key('auth_launching_rocket_image'),
                              width: 130,
                              height: 130,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/rocket.png',
                                key: const Key('auth_launching_rocket_image'),
                                width: 130,
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Dynamic Particle Emitter attached to rocket's thruster base
                            if (_controller.value > 0.04)
                              CustomPaint(
                                size: const Size(120, 160),
                                painter: ThrusterParticlePainter(
                                    progress: _controller.value),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class IgnitionBloomPainter extends CustomPainter {
  final double progress;
  IgnitionBloomPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Peaks around progress 0.2 during rumble/ignition, then smoothly fades out
    final double bloomOpacity;
    if (progress <= 0.2) {
      bloomOpacity = progress / 0.2;
    } else {
      bloomOpacity = (1.0 - (progress - 0.2) / 0.5).clamp(0.0, 1.0);
    }

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 1.1,
        colors: [
          const Color(0xFFFF6A00).withOpacity(bloomOpacity * 0.75),
          const Color(0xFF00F2FE).withOpacity(bloomOpacity * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant IgnitionBloomPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ThrusterParticlePainter extends CustomPainter {
  final double progress;
  ThrusterParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // 1. Core Flickering Flame Polygon
    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          const Color(0xFFFFEE55),
          const Color(0xFFFF6A00),
          const Color(0xFF00F2FE).withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65));

    final flicker = math.sin(progress * 80) * 10;
    final flamePath = Path()
      ..moveTo(centerX - 16, 0)
      ..lineTo(centerX + 16, 0)
      ..lineTo(centerX, size.height * 0.6 + flicker)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    // 2. Expanding Translucent Smoke Puffs (Color(0x33A0AEC0) fading to 0% opacity)
    const smokeBaseColor = Color(0x33A0AEC0);
    final smokePaint = Paint()..style = PaintingStyle.fill;

    const int numSmokePuffs = 16;
    for (int i = 0; i < numSmokePuffs; i++) {
      final double seed = (i * 0.137 + 0.05);
      final double puffProgress = ((progress * 3.5 + seed) % 1.0);
      final double puffY = puffProgress * size.height;
      final double driftX =
          math.sin(seed * 60 + progress * 20) * (20 + puffProgress * 35);
      final double puffRadius = 12.0 + puffProgress * 28.0;
      final double puffOpacity = (1.0 - puffProgress).clamp(0.0, 1.0);

      smokePaint.color = smokeBaseColor.withOpacity(0.20 * puffOpacity);
      smokePaint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, 6 + puffProgress * 6);
      canvas.drawCircle(
          Offset(centerX + driftX, puffY), puffRadius, smokePaint);
    }

    // 3. Rapid glowing yellow-to-orange-to-cyan circular sparks
    final sparkPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const int numSparks = 24;
    for (int i = 0; i < numSparks; i++) {
      final double seed = (i * 0.219 + 0.1);
      final double sparkProgress = ((progress * 6.0 + seed) % 1.0);
      final double sparkY = sparkProgress * (size.height * 0.85);
      final double sparkDriftX =
          math.sin(seed * 90 + progress * 40) * (10 + sparkProgress * 25);
      final double sparkRadius = (4.0 - sparkProgress * 2.2).clamp(1.5, 4.0);
      final double sparkOpacity = (1.0 - sparkProgress).clamp(0.0, 1.0);

      // Color transition: yellow -> orange -> cyan
      final Color sparkColor;
      if (sparkProgress < 0.35) {
        sparkColor = Color.lerp(
          const Color(0xFFFFEE55),
          const Color(0xFFFF6A00),
          sparkProgress / 0.35,
        )!;
      } else {
        sparkColor = Color.lerp(
          const Color(0xFFFF6A00),
          const Color(0xFF00F2FE),
          (sparkProgress - 0.35) / 0.65,
        )!;
      }

      sparkPaint.color = sparkColor.withOpacity(sparkOpacity * 0.9);
      canvas.drawCircle(
          Offset(centerX + sparkDriftX, sparkY), sparkRadius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ThrusterParticlePainter oldDelegate) => true;
}
