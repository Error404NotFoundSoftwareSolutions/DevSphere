import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Reusable neon ambient background widget featuring:
/// - Dark obsidian theme (#050508)
/// - Ethereal neon cyan (#00F2FE) & deep blue (#0051FF) radial light beams
/// - Animated fluid waves powered by Flutter Fragment Shader (shaders/aurora.frag)
/// - Smooth procedural fallback for headless test runners
/// - Vignette overlay and blur effects
class NeonGlowBackground extends StatefulWidget {
  final Widget? child;

  const NeonGlowBackground({super.key, this.child});

  @override
  State<NeonGlowBackground> createState() => _NeonGlowBackgroundState();
}

class _NeonGlowBackgroundState extends State<NeonGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.FragmentShader? _shader;
  bool _shaderLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTestEnvironment) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/aurora.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shaderLoadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const obsidian = Color(0xFF050508);
    const electricCyan = Color(0xFF00F2FE);
    const deepBlue = Color(0xFF0051FF);

    return Scaffold(
      backgroundColor: obsidian,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dark obsidian base backdrop
          const ColoredBox(color: obsidian),

          // 2. Animated fluid wave layer (Fragment Shader or procedural fallback)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final elapsedSeconds =
                    _controller.value * _controller.duration!.inSeconds;
                if (_shader != null && !_shaderLoadFailed) {
                  return CustomPaint(
                    painter: _AuroraShaderPainter(_shader!, elapsedSeconds),
                  );
                }
                return CustomPaint(
                  painter: _AuroraProceduralPainter(_controller.value),
                );
              },
            ),
          ),

          // 3. Electric cyan and deep blue radial ambient light beams
          Positioned(
            top: -100,
            left: -80,
            width: 480,
            height: 480,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      electricCyan.withOpacity(0.18),
                      electricCyan.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            width: 540,
            height: 540,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      deepBlue.withOpacity(0.24),
                      deepBlue.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 4. Subtle vignette overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.25,
                    colors: [
                      Colors.transparent,
                      obsidian.withOpacity(0.4),
                      obsidian.withOpacity(0.75),
                    ],
                    stops: const [0.45, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 5. Child content (e.g. login form, landing hero, glassmorphism cards)
          if (widget.child != null) Positioned.fill(child: widget.child!),
        ],
      ),
    );
  }
}

class _AuroraShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _AuroraShaderPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraShaderPainter oldDelegate) =>
      oldDelegate.time != time;
}

class _AuroraProceduralPainter extends CustomPainter {
  final double animationValue;

  _AuroraProceduralPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cyan = Color(0xFF00F2FE);
    const deepBlue = Color(0xFF0051FF);
    const violet = Color(0xFF6E0DD0);

    final t = animationValue * 2 * math.pi;

    for (int i = 1; i <= 4; i++) {
      final path = Path();
      final freq = 0.0035 * i;
      final speed = t * (0.35 + 0.15 * i);
      final baseY = size.height * (0.38 + 0.07 * i);

      for (double x = 0; x <= size.width; x += 10) {
        final y = baseY +
            math.sin(x * freq + speed) * 32.0 +
            math.cos(x * freq * 0.65 - speed * 0.35) * 18.0;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final color = Color.lerp(cyan, deepBlue, (i - 1) / 3.0)!;

      // Glow halo
      paint.strokeWidth = 10.0;
      paint.color = Color.lerp(color, violet, 0.3)!.withOpacity(0.08);
      canvas.drawPath(path, paint);

      // Ribbon spine
      paint.strokeWidth = 2.0;
      paint.color = color.withOpacity(0.5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraProceduralPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
