import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Typography Engine for the Zen Studio Aesthetic.
class ZenTypography {
  // Editorial Headers
  static TextStyle get editorialHeader => GoogleFonts.montserrat(
        fontSize: 40,
        fontWeight: FontWeight.w300,
        letterSpacing: 4.0,
      );

  // Structural Labels
  static TextStyle get structuralLabel => GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.0,
      );

  // Technical Data (Monospace)
  static TextStyle get techData => GoogleFonts.jetBrainsMono(
        fontSize: 54,
        fontWeight: FontWeight.w400,
        letterSpacing: -2.0,
      );

  // Body Text
  static TextStyle get body => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );
}
