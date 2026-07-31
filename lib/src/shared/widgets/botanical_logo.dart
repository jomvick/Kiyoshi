import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';

class BotanicalLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showPrismaticHalo;

  const BotanicalLogo({
    super.key,
    this.size = 40.0,
    required this.color,
    this.showPrismaticHalo = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: BotanicalLogoPainter(
        color: color,
        showPrismaticHalo: showPrismaticHalo,
      ),
    );
  }
}

class BotanicalLogoPainter extends CustomPainter {
  final Color color;
  final bool showPrismaticHalo;

  BotanicalLogoPainter({
    required this.color,
    this.showPrismaticHalo = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    if (showPrismaticHalo) {
      _drawPrismaticHalo(canvas);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Center Petal: Elegant vertical leaf
    final centerPetal = Path()
      ..moveTo(50, 15)
      ..cubicTo(64, 40, 62, 70, 50, 78)
      ..cubicTo(38, 70, 36, 40, 50, 15)
      ..close();

    // Left Petal: Outward sweeping crescent leaf
    final leftPetal = Path()
      ..moveTo(44, 78)
      ..cubicTo(28, 72, 18, 60, 15, 45)
      ..cubicTo(26, 52, 36, 64, 44, 78)
      ..close();

    // Right Petal: Outward sweeping crescent leaf
    final rightPetal = Path()
      ..moveTo(56, 78)
      ..cubicTo(72, 72, 82, 60, 85, 45)
      ..cubicTo(74, 52, 64, 64, 56, 78)
      ..close();

    canvas.drawPath(centerPetal, paint);
    canvas.drawPath(leftPetal, paint);
    canvas.drawPath(rightPetal, paint);

    canvas.restore();
  }

  void _drawPrismaticHalo(Canvas canvas) {
    const center = Offset(50, 50);
    const rect = Rect.fromLTWH(0, 0, 100, 100);

    final glow = Paint()
      ..color = KiyoshiZenTokens.spectralColors[0].withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 44, glow);

    final ring = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFA8E6CF), // Mint green
          Color(0xFF88D8B0), // Cyan
          Color(0xFFA2D5F2), // Soft blue
          Color(0xFFD6A2E8), // Lavender
          Color(0xFFFFB7B2), // Soft pink
          Color(0xFFFFDAB9), // Peach
          Color(0xFFA8E6CF), // Mint green
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..isAntiAlias = true;
    canvas.drawCircle(center, 44, ring);

    final innerGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, 42.5, innerGlow);
  }

  @override
  bool shouldRepaint(covariant BotanicalLogoPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showPrismaticHalo != showPrismaticHalo;
  }
}
