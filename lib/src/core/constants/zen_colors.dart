import 'package:flutter/material.dart';

/// Centralized Zen Palette (Sauge & Ardoise)
/// Following the "No-Line" rule and glassmorphism principles.
class ZenColors {
  // === SAUGE (Sage) ===
  static const Color sageLight = Color(0xFFE8F5E9);
  static const Color sageBase = Color(0xFFC8E6C9);
  static const Color sageDark = Color(0xFF3D5A5D); // Slate Green / Ardoise
  
  // === ARDOISE (Slate) ===
  static const Color slateBase = Color(0xFF1E293B);
  static const Color slateLight = Color(0xFF4B5563);
  
  // === CANVAS & SURFACES (Light) ===
  static const Color canvas = Color(0xFFF5F5F5); // Matte Off-White
  static const Color glassFill = Color(0x66FFFFFF); // 40% White
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% White
  
  // === SPECTRAL (Prismatic) ===
  static const List<Color> spectralColors = [
    Color(0xFFFFD1D1),
    Color(0xFFD1FFD1),
    Color(0xFFD1F1FF),
    Color(0xFFE4D1FF),
  ];
  
  // === UI ELEMENTS (Light) ===
  static const Color primary = sageDark;
  static const Color onPrimary = Colors.white;
  static const Color background = canvas;
  static const Color onBackground = slateBase;
  static const Color onSurfaceVariant = slateLight;

  // ============================================================
  // === DARK MODE — "Warm Charcoal" (inspired by Claude's UI) ===
  // Not a near-black/blue-black theme: warm, soft charcoal tones
  // so the Zen glassmorphism stays cozy instead of cold/harsh.
  // ============================================================

  /// Deepest layer — app background (Claude-like warm charcoal).
  static const Color darkCanvas = Color(0xFF262624);

  /// Slightly lower than canvas — for sunken/inset areas (sidebars).
  static const Color darkSurfaceLowest = Color(0xFF1F1E1D);

  /// Base card/panel surface, one step up from canvas.
  static const Color darkSurfaceLow = Color(0xFF2B2A28);

  /// Standard surface (cards, list tiles).
  static const Color darkSurface = Color(0xFF30302E);

  /// Elevated surface (hover, modals, popovers).
  static const Color darkSurfaceHigh = Color(0xFF3A3937);

  /// Warm off-white text (not pure #FFFFFF — easier on the eyes).
  static const Color darkOnBackground = Color(0xFFECEBE4);

  /// Secondary/muted warm gray text.
  static const Color darkOnSurfaceVariant = Color(0xFFB3B1A8);

  /// Warm neutral outline/border, low contrast by design ("No-Line" rule).
  static const Color darkOutline = Color(0xFF47453F);
  static const Color darkOutlineVariant = Color(0xFF3A3835);

  /// Glass fill/border tuned for a dark warm background — frosted
  /// charcoal instead of frosted white, so panels don't look like
  /// bright rectangles floating on a dark canvas.
  static const Color darkGlassFill = Color(0x54383734); // ~33% warm charcoal
  static const Color darkGlassBorder = Color(0x1FFFFFFF); // 12% white hairline

  /// Primary accent stays legible on dark: a lighter sage/teal so it
  /// doesn't sink into the charcoal background.
  static const Color darkPrimary = Color(0xFF8FBDB8);
  static const Color darkOnPrimary = Color(0xFF0E1A19);
}
