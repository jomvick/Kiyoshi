import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';

class KiyoshiGlassCard extends StatelessWidget {
  final Widget child;
  final double? radius;
  final double? opacity;
  final double? blur;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const KiyoshiGlassCard({
    super.key,
    required this.child,
    this.radius,
    this.opacity,
    this.blur,
    this.borderColor,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? 16.0;
    final effectiveOpacity = opacity ?? 0.05;
    final effectiveBlur = blur ?? KiyoshiZenTokens.blurSigma;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: effectiveOpacity),
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: Border.all(
              color: borderColor ?? KiyoshiZenTokens.glassBorder.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
