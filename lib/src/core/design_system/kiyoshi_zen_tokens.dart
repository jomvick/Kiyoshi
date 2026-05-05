import 'package:flutter/material.dart';

/// Kiyoshi Zen Studio — single source of truth for the Zen mockup layer.
/// Spacing continues to use [AppTheme.space*] for grid alignment.
abstract final class KiyoshiZenTokens {
  /// Matte off-white field (#F5F5F5).
  static const Color canvas = Color(0xFFF5F5F5);

  /// Pale sage (Material Green 100 family).
  static const Color sage = Color(0xFFC8E6C9);

  /// Soft mint-teal (aligns with app mint surfaces).
  static const Color mintTeal = Color(0xFFE0F2F1);

  /// Glass fill — frosted white.
  static const Color glassFill = Color(0x38FFFFFF);

  /// Default glass edge.
  static const Color glassBorder = Color(0x6AFFFFFF);

  /// Uniform card corner — 20px.
  static const double radiusCard = 20;

  /// Backdrop blur (Flutter `sigma`; high values wash out content behind glass).
  /// ~10 keeps a light frost while keeping cards and text readable.
  static const double blurSigma = 10;

  /// Spectral stroke colors (iridescent, pastel).
  static const List<Color> spectralColors = [
    Color(0xFF5EEAD4),
    Color(0xFF7C8CFF),
    Color(0xFFFF6B9A),
    Color(0xFF86EFAC),
    Color(0xFF5EEAD4),
  ];

  /// Vertical mist gradient for orb overlays.
  static const LinearGradient sageMintVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sage, mintTeal],
  );

  /// Horizontal blend for some panels.
  static const LinearGradient sageMintHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [sage, mintTeal],
  );
}
