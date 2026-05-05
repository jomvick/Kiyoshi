import 'package:flutter/material.dart';

/// Prismatic Painter for the "Light Leak" effect
/// Draws a subtle, moving spectral highlight that reacts to mouse position
class PrismaticPainter extends CustomPainter {
  final Offset mousePosition;
  final double radius;
  final double opacity;

  PrismaticPainter({
    required this.mousePosition,
    required this.radius,
    this.opacity = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mousePosition == Offset.zero) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Calculate normalized mouse position
    final localMouse = mousePosition;
    
    // Create the spectral gradient
    final gradient = RadialGradient(
      center: Alignment(
        (localMouse.dx / size.width) * 2 - 1,
        (localMouse.dy / size.height) * 2 - 1,
      ),
      radius: 0.8,
      colors: [
        const Color(0x80FFD1D1).withValues(alpha: opacity),
        const Color(0x80D1FFD1).withValues(alpha: opacity * 0.8),
        const Color(0x80D1F1FF).withValues(alpha: opacity * 0.6),
        const Color(0x80E4D1FF).withValues(alpha: opacity * 0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, paint);
    
    // Add a secondary rim highlight
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    canvas.drawRRect(rrect, rimPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PrismaticPainter oldDelegate) {
    return oldDelegate.mousePosition != mousePosition ||
           oldDelegate.radius != radius ||
           oldDelegate.opacity != opacity;
  }
}
