import 'package:flutter/material.dart';

/// A custom painter that draws a rotating spectral/rainbow border.
class PrismaticBorderPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final double radius;
  final double strokeWidth;

  PrismaticBorderPainter({
    required this.animation,
    required this.colors,
    required this.radius,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(animation * 6.28),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant PrismaticBorderPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
