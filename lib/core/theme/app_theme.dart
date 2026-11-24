import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitrak/core/animations/app_page_route.dart';

class AppColors {
  // Brand Neo-Health Palette (Matching reference design)
  static const Color limeAccent = Color(0xFFD2EB70); // Vibrant Electric Lime / Chartreuse
  static const Color limeAccentLight = Color(0xFFEAF5B8);
  static const Color limeAccentDark = Color(0xFFBCE33A);
  
  static const Color lavenderAccent = Color(0xFFB6B8F8); // Soft Periwinkle / Lavender Purple
  static const Color lavenderLight = Color(0xFFE8E9FD);
  static const Color lavenderDark = Color(0xFF9093EE);

  // Pista / Pistachio Green Palette (Synced with homescreen green)
  static const Color pistaGreen = Color(0xFFD2EB70); // Homescreen green
  static const Color pistaGreenLight = Color(0xFFEAF5B8);
  static const Color pistaGreenDark = Color(0xFFBCE33A);

  static const Color obsidianBlack = Color(0xFF16181A); // Deep Matte Charcoal / Black Surface
  static const Color charcoalSurface = Color(0xFF1E2124);
  static const Color charcoalCard = Color(0xFF282B2F);
  static const Color charcoalBorder = Color(0xFF33373D);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121416);
  static const Color darkSurface = Color(0xFF1A1C1E);
  static const Color darkSurfaceLow = Color(0xFF16181A);
  static const Color darkSurfaceHigh = Color(0xFF25282C);
  static const Color darkPrimary = Color(0xFFD2EB70); // Lime accent as primary punch
  static const Color darkPrimaryContainer = Color(0xFF2A3614);
  static const Color darkOnPrimary = Color(0xFF16181A);
  static const Color darkSecondary = Color(0xFFB6B8F8); // Lavender accent
  static const Color darkSecondaryContainer = Color(0xFF28294A);
  static const Color darkOnSurface = Color(0xFFF3F4F6);
  static const Color darkOnSurfaceVariant = Color(0xFF9DA2AA);
  static const Color darkOutline = Color(0xFF3E4249);
  static const Color darkOutlineVariant = Color(0xFF2B2E33);
  static const Color darkTertiary = Color(0xFFF095A6);
  static const Color darkTertiaryContainer = Color(0xFF4C2730);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF3F4F6); // Soft clean grey/off-white canvas
  static const Color lightSurface = Color(0xFFFFFFFF); // Crisp clean white cards
  static const Color lightSurfaceLow = Color(0xFFF8F9FA);
  static const Color lightSurfaceHigh = Color(0xFFEBECEF);
  static const Color lightPrimary = Color(0xFF16181A); // Deep black primary for text/headers
  static const Color lightPrimaryAccent = Color(0xFFD2EB70); // Lime accent pop
  static const Color lightPrimaryContainer = Color(0xFFEBF6BF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF7A7DE8);
  static const Color lightSecondaryContainer = Color(0xFFE8E9FD);
  static const Color lightOnSurface = Color(0xFF16181A);
  static const Color lightOnSurfaceVariant = Color(0xFF72767E);
  static const Color lightOutline = Color(0xFFE2E4E8);
  static const Color lightOutlineVariant = Color(0xFFECEEF2);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        secondary: AppColors.darkSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkOnPrimary,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        tertiary: AppColors.darkTertiary,
        tertiaryContainer: AppColors.darkTertiaryContainer,
      ),
      textTheme: GoogleFonts.hankenGroteskTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.hankenGrotesk(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
            color: AppColors.darkOnSurface,
          ),
          headlineLarge: GoogleFonts.hankenGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: AppColors.darkOnSurface,
          ),
          headlineMedium: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.01,
            color: AppColors.darkPrimary,
          ),
          titleMedium: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkOnSurface,
          ),
          bodyLarge: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.darkOnSurface,
          ),
          bodyMedium: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.darkOnSurfaceVariant,
          ),
          labelSmall: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: AppColors.darkOnSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        secondary: AppColors.lightSecondary,
        secondaryContainer: AppColors.lightSecondaryContainer,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.lightOnPrimary,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        outline: AppColors.lightOutline,
        outlineVariant: AppColors.lightOutlineVariant,
      ),
      textTheme: GoogleFonts.hankenGroteskTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.hankenGrotesk(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
            color: AppColors.lightOnSurface,
          ),
          headlineLarge: GoogleFonts.hankenGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: AppColors.lightOnSurface,
          ),
          headlineMedium: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.01,
            color: AppColors.lightOnSurface,
          ),
          titleMedium: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurface,
          ),
          bodyLarge: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.lightOnSurface,
          ),
          bodyMedium: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.lightOnSurfaceVariant,
          ),
          labelSmall: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
