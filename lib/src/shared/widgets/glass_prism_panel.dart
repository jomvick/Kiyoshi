import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';

/// Frosted glass panel: blur 20, radius 20, optional razor-thin spectral outline.
class GlassPrismPanel extends StatelessWidget {
  final Widget child;
  final bool spectralOutline;
  final EdgeInsetsGeometry? padding;

  const GlassPrismPanel({
    super.key,
    required this.child,
    this.spectralOutline = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    const radius = KiyoshiZenTokens.radiusCard;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warm charcoal frost in dark mode instead of a white panel floating
    // on a dark canvas; sage tint kept subtle either way.
    final fillColor = isDark
        ? const Color(0xFF383734).withValues(alpha: 0.58)
        : Colors.white.withValues(alpha: 0.52);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFF94A3B8).withValues(alpha: 0.28);
    final gradientColors = isDark
        ? [
            KiyoshiZenTokens.mintTeal.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.04),
            KiyoshiZenTokens.sage.withValues(alpha: 0.05),
          ]
        : [
            KiyoshiZenTokens.mintTeal.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.14),
            KiyoshiZenTokens.sage.withValues(alpha: 0.04),
          ];
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.24)
        : Colors.black.withValues(alpha: 0.06);

    return RepaintBoundary(
      child: CustomPaint(
      painter: spectralOutline
          ? _SpectralBorderPainter(radius: radius)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: KiyoshiZenTokens.blurSigma,
            sigmaY: KiyoshiZenTokens.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              // Stronger base fill so text and controls stay legible on misty bg.
              color: fillColor,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: KiyoshiZenTokens.sage.withValues(alpha: isDark ? 0.06 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _SpectralBorderPainter extends CustomPainter {
  final double radius;

  _SpectralBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );

    final glowPaint = Paint()
      ..color = KiyoshiZenTokens.spectralColors[0].withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final borderPaint = Paint()
      ..shader = const SweepGradient(
        colors: KiyoshiZenTokens.spectralColors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpectralBorderPainter oldDelegate) {
    return radius != oldDelegate.radius;
  }
}
