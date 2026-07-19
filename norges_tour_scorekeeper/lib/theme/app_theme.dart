import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// SpikeDunk · Norges Tour — ThemeData
/// Redesigned with a premium dark-theme look.
class AppTheme {
  AppTheme._();

  // ── Shared shape / radius ─────────────────────────────────────
  static const double radiusCard   = 24.0; // Larger for a softer, premium feel
  static const double radiusRow    = 16.0;
  static const double radiusChip   = 999.0; // pill
  static const double radiusInput  = 16.0;
  static const double radiusButton = 16.0;
  static const double radiusBadge  = 8.0;

  // ── Elevation / shadows ───────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3,  offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get shadowLg => [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 16)),
    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get shadowCoral => [
    BoxShadow(color: AppColors.coral.withOpacity(0.40), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  // ── Spacing ───────────────────────────────────────────────────
  static const double pageHPad    = 16.0;
  static const double sectionGap  = 24.0;
  static const double rowGap      = 9.0;
  static const double cardPad     = 15.0;

  // ══════════════════════════════════════════════════════════════
  // DARK THEME (Premium Night mode)
  // ══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.nightSurface0, // Use the new deep background
      primaryColor: AppColors.coral,
      colorScheme: ColorScheme.dark(
        primary:        AppColors.coral,
        secondary:      AppColors.blueBright,
        surface:        AppColors.nightSurface1,
        onPrimary:      Colors.white,
        onSurface:      AppColors.nightInk,
        outline:        Colors.white.withOpacity(0.05),
      ),
      textTheme: _textTheme(AppColors.nightInk),
      fontFamily: GoogleFonts.inter().fontFamily ?? GoogleFonts.schibstedGrotesk().fontFamily, // Inter for a cleaner modern look if available
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.nightInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppText.dispH2(20).copyWith(color: AppColors.nightInk, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.nightSurface1.withOpacity(0.95),
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.nightInk3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.nightSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56), // slightly taller for better tap targets
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: AppText.uiCta.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.nightInk,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
          textStyle: AppText.uiCta.copyWith(color: AppColors.nightInk, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightSurface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        hintStyle: AppText.uiBody.copyWith(color: AppColors.nightInk3),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.05), thickness: 1, space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.nightSurface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        elevation: 10,
        titleTextStyle: AppText.dispH2(20).copyWith(color: AppColors.nightInk),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.nightSurface1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      )
    );
    return base;
  }

  // NOTE: Light theme is preserved for reference but the app will force dark mode
  static ThemeData get light => dark; // Forces dark theme

  // ── shared text theme ─────────────────────────────────────────
  static TextTheme _textTheme(Color color) => TextTheme(
    displayLarge:  AppText.dispScore(48).copyWith(color: color),
    displayMedium: AppText.dispH1(34).copyWith(color: color),
    displaySmall:  AppText.dispH1(26).copyWith(color: color),
    headlineLarge: AppText.dispH2(24).copyWith(color: color),
    headlineMedium:AppText.dispH2(20).copyWith(color: color),
    headlineSmall: AppText.dispKicker(15).copyWith(color: color),
    titleLarge:    AppText.uiTitle.copyWith(fontSize: 18, color: color),
    titleMedium:   AppText.uiTitle.copyWith(fontSize: 16, color: color),
    titleSmall:    AppText.uiTitle.copyWith(fontSize: 14, color: color),
    bodyLarge:     AppText.uiBody.copyWith(fontSize: 16, color: color),
    bodyMedium:    AppText.uiBody.copyWith(color: color),
    bodySmall:     AppText.uiCaption.copyWith(color: color.withOpacity(0.7)),
    labelLarge:    AppText.uiCta.copyWith(color: color),
    labelMedium:   AppText.monoMd.copyWith(color: color),
    labelSmall:    AppText.monoSm.copyWith(color: color),
  );
}
