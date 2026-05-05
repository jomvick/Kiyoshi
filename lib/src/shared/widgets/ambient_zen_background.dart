import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';

/// Misty forest depth: matte canvas + large soft sage/mint orbs + light noise.
class AmbientZenBackground extends StatelessWidget {
  final Widget child;

  const AmbientZenBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: KiyoshiZenTokens.canvas),
              ..._buildOrbs(),
              CustomPaint(
                painter: _ZenNoisePainter(
                  opacity: 0.010,
                  seed: 42,
                  density: 0.04,
                ),
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  List<Widget> _buildOrbs() {
    return [
      _Orb(
        top: -120,
        left: -80,
        width: 420,
        height: 380,
        colors: [
          KiyoshiZenTokens.sage.withValues(alpha: 0.32),
          KiyoshiZenTokens.mintTeal.withValues(alpha: 0.0),
        ],
        blur: 60,
      ),
      _Orb(
        top: 80,
        right: -100,
        width: 480,
        height: 440,
        colors: [
          KiyoshiZenTokens.mintTeal.withValues(alpha: 0.28),
          KiyoshiZenTokens.sage.withValues(alpha: 0.0),
        ],
        blur: 70,
      ),
      _Orb(
        bottom: -60,
        left: 120,
        width: 520,
        height: 360,
        colors: [
          KiyoshiZenTokens.sage.withValues(alpha: 0.22),
          KiyoshiZenTokens.mintTeal.withValues(alpha: 0.08),
        ],
        blur: 55,
      ),
      _Orb(
        bottom: 40,
        right: 40,
        width: 300,
        height: 300,
        colors: [
          KiyoshiZenTokens.mintTeal.withValues(alpha: 0.20),
          KiyoshiZenTokens.sage.withValues(alpha: 0.0),
        ],
        blur: 45,
      ),
    ];
  }
}

class _Orb extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double width;
  final double height;
  final List<Color> colors;
  final double blur;

  const _Orb({
    required this.width,
    required this.height,
    required this.colors,
    required this.blur,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ClipOval(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors,
                stops: const [0.35, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZenNoisePainter extends CustomPainter {
  final double opacity;
  final int seed;
  final double density;

  const _ZenNoisePainter({
    required this.opacity,
    required this.seed,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final count = (size.width * size.height * density).clamp(800.0, 12000.0);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ZenNoisePainter oldDelegate) {
    return opacity != oldDelegate.opacity ||
        seed != oldDelegate.seed ||
        density != oldDelegate.density;
  }
}
