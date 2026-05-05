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
  final Color baseColor;

  const ZenGlassCard({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.padding = const EdgeInsets.all(24.0),
    this.opacity = 0.4,
    this.blurSigma = 20.0,
    this.hasShadow = false,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: baseColor.withValues(alpha: (opacity * 2).clamp(0.0, 1.0)), // Subtle border
              width: 1.0,
            ),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
