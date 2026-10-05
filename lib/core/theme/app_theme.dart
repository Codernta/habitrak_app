import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitrak/core/animations/app_page_route.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xff121412);
  static const Color darkSurface = Color(0xff1e201e);
  static const Color darkSurfaceLow = Color(0xff1a1c1a);
  static const Color darkSurfaceHigh = Color(0xff292a28);
  static const Color darkPrimary = Color(0xffb0ceb2);
  static const Color darkPrimaryContainer = Color(0xff334d38);
  static const Color darkOnPrimary = Color(0xff1c3622);
  static const Color darkSecondary = Color(0xffbfc9bf);
  static const Color darkSecondaryContainer = Color(0xff3f4941);
  static const Color darkOnSurface = Color(0xffe2e3df);
  static const Color darkOnSurfaceVariant = Color(0xffc2c8c0);
  static const Color darkOutline = Color(0xff8c928b);
  static const Color darkOutlineVariant = Color(0xff424842);
  static const Color darkTertiary = Color(0xffedb9c3);
  static const Color darkTertiaryContainer = Color(0xffc4949d);

  // Light Theme Colors
  static const Color lightBackground = Color(0xfffaf9f6);
  static const Color lightSurface = Color(0xffffffff);
  static const Color lightSurfaceLow = Color(0xfff2f1ee);
  static const Color lightSurfaceHigh = Color(0xffefeeeb);
  static const Color lightPrimary = Color(0xff8ba88e);
  static const Color lightPrimaryContainer = Color(0xffcceace);
  static const Color lightOnPrimary = Color(0xffffffff);
  static const Color lightSecondary = Color(0xff516870);
  static const Color lightSecondaryContainer = Color(0xffcee7f0);
  static const Color lightOnSurface = Color(0xff2f312f);
  static const Color lightOnSurfaceVariant = Color(0xff615e56);
  static const Color lightOutline = Color(0xffa4a097);
  static const Color lightOutlineVariant = Color(0xffdbdad7);
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
      scaffoldBackgroundColor: AppColors.darkBackground,
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
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02,
            color: AppColors.darkPrimary,
          ),
          headlineLarge: GoogleFonts.hankenGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.01,
            color: AppColors.darkOnSurface,
          ),
          headlineMedium: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppColors.darkPrimary,
          ),
          titleMedium: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.darkOnSurface,
          ),
          bodyLarge: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.darkOnSurface,
          ),
          bodyMedium: GoogleFonts.hankenGrotesk(
            fontSize: 16,
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
      scaffoldBackgroundColor: AppColors.lightBackground,
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
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02,
            color: AppColors.lightPrimary,
          ),
          headlineLarge: GoogleFonts.hankenGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.01,
            color: AppColors.lightOnSurface,
          ),
          headlineMedium: GoogleFonts.hankenGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppColors.lightPrimary,
          ),
          titleMedium: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.lightOnSurface,
          ),
          bodyLarge: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.lightOnSurface,
          ),
          bodyMedium: GoogleFonts.hankenGrotesk(
            fontSize: 16,
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
