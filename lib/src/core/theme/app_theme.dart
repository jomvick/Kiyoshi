import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/core/constants/zen_colors.dart';

enum BlurDensity { low, mid, high }

/// The Translucent Sanctuary - Zen Design System
/// Light theme with "No-Line" rule, glassmorphism, and editorial typography
class AppTheme {
  // === ZEN NEUTRAL PALETTE ===
  static const Color background = ZenColors.background;
  static const Color backgroundColor = background;
  static const Color onBackground = ZenColors.onBackground;
  
  // Sage & Mint Gradient Tokens
  static const Color sageGreen = ZenColors.sageBase;
  static const Color sage = sageGreen;
  static const Color mintTeal = Color(0xFFE0F2F1);
  
  // Primary - Slate Green / Teal
  static const Color primary = ZenColors.primary;
  static const Color onPrimary = ZenColors.onPrimary;
  static const Color primaryDim = Color(0xFF354B4F);
  static const Color primaryContainer = Color(0xFFBCE1DF);
  static const Color onPrimaryContainer = Color(0xFF00201F);
  static const Color inversePrimary = Color(0xFFBCE1DF);

  // Surface hierarchy (layering principle)
  static const Color surface = Color(0xFFE0F2F1);
  static const Color surfaceContainerLow = Color(0xFFF1F8F8);
  static const Color surfaceContainer = Color(0xFFE4F4F3);
  static const Color surfaceContainerHigh = Color(0xFFD6EAE9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFBCE1DF);
  
  // Secondary - Neutral Gray
  static const Color secondary = Color(0xFF5E5F5F);
  static const Color secondaryDim = Color(0xFF515353);
  static const Color secondaryContainer = Color(0xFFE2E2E2);
  static const Color onSecondary = Color(0xFFF9F9F8);
  static const Color onSecondaryContainer = Color(0xFF505252);
  
  // Tertiary - Soft Blue
  static const Color tertiary = Color(0xFF496272);
  static const Color tertiaryDim = Color(0xFF3D5666);
  static const Color tertiaryContainer = Color(0xFFC8E3F7);
  static const Color onTertiary = Color(0xFFF4F9FF);
  static const Color onTertiaryContainer = Color(0xFF3A5363);
  
  // Utility colors
  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);
  static const Color onSurfaceVariant = ZenColors.onSurfaceVariant;
  static const Color surfaceTint = Color(0xFF476368);
  
  // Status colors
  static const Color error = Color(0xFF9F403D);
  static const Color errorContainer = Color(0xFFFE8983);
  static const Color onError = Color(0xFFFFF7F6);
  static const Color onErrorContainer = Color(0xFF752121);
  
  // Priority colors (adapted to Zen palette)
  static const Color priorityHigh = Color(0xFF9F403D);
  static const Color priorityMedium = Color(0xFF476368);
  static const Color priorityLow = Color(0xFF5E5F5F);
  
  // === GLASSMORPHISM (Enhanced for Zen Studio) ===
  static const Color glassFill = ZenColors.glassFill;
  static const Color glassBorder = ZenColors.glassBorder;
  static const double blurStrength = 20.0; // Polished 20px blur
  
  static double getBlur(BlurDensity density) {
    switch (density) {
      case BlurDensity.low: return 12.0;
      case BlurDensity.mid: return 24.0;
      case BlurDensity.high: return 40.0;
    }
  }
  
  // === SHADOWS (Crisp, Apple-style Drop Shadows) ===
  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: const Color(0x0A000000), // 4% pure black
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x05000000), // 2% black for rim
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> ambientShadowHover = [
    BoxShadow(
      color: const Color(0x14000000), // 8% black
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: -2,
    ),
  ];
  
  // === BORDER RADIUS (Soft rounded corners) ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0; // Standardized to 20px
  static const double radiusXLarge = 24.0;
  static const double radius2XLarge = 32.0;
  static const double radiusFull = 9999.0;
  
  // === SPACING (Generous negative space) ===
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double space2XLarge = 48.0;
  static const double frameMargin = 40.0; // "Frame within a Frame"
  
  // === ANIMATIONS ===
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  
  // === THEME DATA ===
  static ThemeData get lightTheme {
    final baseTextTheme = const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: onBackground,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: onBackground,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onBackground,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onBackground,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onBackground,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: onSurfaceVariant,
        letterSpacing: 1.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onBackground,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onBackground,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );

    final montserrat = GoogleFonts.montserratTextTheme(baseTextTheme);
    final inter = GoogleFonts.interTextTheme(baseTextTheme);
    final jetbrains = GoogleFonts.jetBrainsMonoTextTheme(baseTextTheme);
    
    final mergedTextTheme = inter.copyWith(
      displayLarge: montserrat.displayLarge?.copyWith(letterSpacing: -0.5),
      displayMedium: montserrat.displayMedium?.copyWith(letterSpacing: -0.5),
      displaySmall: montserrat.displaySmall?.copyWith(letterSpacing: -0.2),
      headlineLarge: montserrat.headlineLarge?.copyWith(letterSpacing: 0.5),
      headlineMedium: montserrat.headlineMedium?.copyWith(letterSpacing: 0.5),
      headlineSmall: montserrat.headlineSmall?.copyWith(letterSpacing: 0.5),
      titleLarge: montserrat.titleLarge?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
      titleMedium: montserrat.titleMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w700),
      titleSmall: jetbrains.titleSmall?.copyWith(letterSpacing: 2.0, fontSize: 10, fontWeight: FontWeight.w600),
      labelSmall: jetbrains.labelSmall?.copyWith(letterSpacing: 1.8, fontSize: 10),
      bodySmall: jetbrains.bodySmall?.copyWith(letterSpacing: 0.5, fontSize: 11),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: KiyoshiZenTokens.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppTheme.primary,
        primaryContainer: AppTheme.primaryContainer,
        onPrimary: AppTheme.onPrimary,
        onPrimaryContainer: AppTheme.onPrimaryContainer,
        secondary: AppTheme.secondary,
        secondaryContainer: AppTheme.secondaryContainer,
        onSecondary: AppTheme.onSecondary,
        onSecondaryContainer: AppTheme.onSecondaryContainer,
        tertiary: AppTheme.tertiary,
        tertiaryContainer: AppTheme.tertiaryContainer,
        onTertiary: AppTheme.onTertiary,
        onTertiaryContainer: AppTheme.onTertiaryContainer,
        surface: AppTheme.surface,
        surfaceContainerLow: AppTheme.surfaceContainerLow,
        surfaceContainerLowest: AppTheme.surfaceContainerLowest,
        surfaceContainerHigh: AppTheme.surfaceContainerHigh,
        onSurface: AppTheme.onBackground,
        onSurfaceVariant: AppTheme.onSurfaceVariant,
        outline: AppTheme.outline,
        outlineVariant: AppTheme.outlineVariant,
        error: AppTheme.error,
        errorContainer: AppTheme.errorContainer,
        onError: AppTheme.onError,
        onErrorContainer: AppTheme.onErrorContainer,
        inversePrimary: AppTheme.inversePrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: glassBorder, width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      iconTheme: const IconThemeData(
        color: onSurfaceVariant,
        size: 20,
      ),
      textTheme: mergedTextTheme,
    );
  }
  
  static BoxDecoration glassPanel({double radius = radiusLarge}) {
    return BoxDecoration(
      color: glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glassBorder,
        width: 1,
      ),
      boxShadow: ambientShadow,
    );
  }
  
  static BoxDecoration ultraGlass({double radius = 20.0}) {
    return BoxDecoration(
      color: glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glassBorder,
        width: 1,
      ),
      boxShadow: ambientShadow,
    );
  }

  static BoxDecoration prismaticDecoration({double radius = radiusLarge}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x80FFD1D1),
          Color(0x80D1FFD1),
          Color(0x80D1F1FF),
          Color(0x80E4D1FF),
        ],
      ),
    );
  }
  
  static BoxDecoration floatingCard({bool isHovered = false}) {
    return BoxDecoration(
      color: surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(
        color: outlineVariant,
        width: 1,
      ),
      boxShadow: isHovered ? ambientShadowHover : ambientShadow,
    );
  }
  
  static BoxDecoration primaryButton({double radius = radiusXLarge}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.primary, AppTheme.primaryDim],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }
  
  static BoxDecoration glassButton({double radius = radiusXLarge}) {
    return BoxDecoration(
      color: surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: outlineVariant,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0x0A000000),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration chip({bool isActive = false}) {
    return BoxDecoration(
      color: isActive ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(radiusFull),
    );
  }
}
