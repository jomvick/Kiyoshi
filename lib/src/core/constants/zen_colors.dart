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
  
  // === CANVAS & SURFACES ===
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
  
  // === UI ELEMENTS ===
  static const Color primary = sageDark;
  static const Color onPrimary = Colors.white;
  static const Color background = canvas;
  static const Color onBackground = slateBase;
  static const Color onSurfaceVariant = slateLight;
}
