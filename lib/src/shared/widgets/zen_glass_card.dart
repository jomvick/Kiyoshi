import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized Glassmorphism container for Kiyoshi's Zen aesthetic.
class ZenGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blurSigma;
  final bool hasShadow;

  /// Base tint of the frosted glass. Defaults to null, which picks a
  /// theme-appropriate tint (white frost in light mode, warm charcoal
  /// frost in dark mode) so the card doesn't render as a bright white
  /// rectangle on a dark background. Pass an explicit color to override.
  final Color? baseColor;

  const ZenGlassCard({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.padding = const EdgeInsets.all(24.0),
    this.opacity = 0.4,
    this.blurSigma = 20.0,
    this.hasShadow = false,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBaseColor =
        baseColor ?? (isDark ? const Color(0xFF383734) : Colors.white);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveBaseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : effectiveBaseColor.withValues(alpha: (opacity * 2).clamp(0.0, 1.0)),
              width: 1.0,
            ),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
