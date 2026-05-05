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

    final centerPetal = Path()
      ..moveTo(50, 10)
      ..cubicTo(35, 35, 30, 75, 50, 85)
      ..cubicTo(70, 75, 65, 35, 50, 10)
      ..close();

    final leftPetal = Path()
      ..moveTo(42, 85)
      ..quadraticBezierTo(25, 75, 10, 45)
      ..cubicTo(5, 75, 20, 95, 42, 85)
      ..close();

    final rightPetal = Path()
      ..moveTo(58, 85)
      ..quadraticBezierTo(75, 75, 90, 45)
      ..cubicTo(95, 75, 80, 95, 58, 85)
      ..close();

    canvas.drawPath(centerPetal, paint);
    canvas.drawPath(leftPetal, paint);
    canvas.drawPath(rightPetal, paint);

    canvas.restore();
  }

  void _drawPrismaticHalo(Canvas canvas) {
    const center = Offset(50, 50);
    final rect = const Rect.fromLTWH(0, 0, 100, 100);

    final glow = Paint()
      ..color = KiyoshiZenTokens.spectralColors[0].withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 46, glow);

    final ring = Paint()
      ..shader = SweepGradient(
        colors: KiyoshiZenTokens.spectralColors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 46, ring);

    final innerGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, 44.5, innerGlow);
  }

  @override
  bool shouldRepaint(covariant BotanicalLogoPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showPrismaticHalo != showPrismaticHalo;
  }
}
