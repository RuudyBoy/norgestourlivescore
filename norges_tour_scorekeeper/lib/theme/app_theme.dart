import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// SpikeDunk · Norges Tour — ThemeData
///
/// Usage in main.dart:
///   MaterialApp(
///     theme: AppTheme.light,
///     darkTheme: AppTheme.dark,
///     themeMode: ThemeMode.system, // or ThemeMode.light to always use light
///   )
class AppTheme {
  AppTheme._();

  // ── Shared shape / radius ─────────────────────────────────────
  static const double radiusCard   = 20.0;
  static const double radiusRow    = 16.0;
  static const double radiusChip   = 999.0; // pill
  static const double radiusInput  = 14.0;
  static const double radiusButton = 14.0;
  static const double radiusBadge  = 8.0;

  // ── Elevation / shadows ───────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: AppColors.ink.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: AppColors.ink.withOpacity(0.05), blurRadius: 3,  offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get shadowLg => [
    BoxShadow(color: AppColors.ink.withOpacity(0.20), blurRadius: 40, offset: const Offset(0, 16)),
    BoxShadow(color: AppColors.ink.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get shadowCoral => [
    BoxShadow(color: AppColors.coral.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  // ── Spacing ───────────────────────────────────────────────────
  static const double pageHPad    = 16.0;
  static const double sectionGap  = 24.0;
  static const double rowGap      = 9.0;
  static const double cardPad     = 15.0;

  // ══════════════════════════════════════════════════════════════
  // LIGHT THEME (Sand & Broadcast)
  // ══════════════════════════════════════════════════════════════
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.coral,
      colorScheme: ColorScheme.light(
        primary:        AppColors.coral,
        primaryContainer: AppColors.coralDeep,
        secondary:      AppColors.blue,
        secondaryContainer: AppColors.blueBright,
        surface:        AppColors.sand0,
        onPrimary:      Colors.white,
        onSecondary:    Colors.white,
        onSurface:      AppColors.ink,
        outline:        AppColors.line,
      ),

      // typography
      textTheme: _textTheme(AppColors.ink),
      fontFamily: GoogleFonts.schibstedGrotesk().fontFamily,

      // app bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppText.dispH2(20).copyWith(color: AppColors.ink),
      ),

      // bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.sand0.withOpacity(0.86),
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.ink3,
        selectedLabelStyle: AppText.uiTab.copyWith(color: AppColors.coral, fontWeight: FontWeight.w800),
        unselectedLabelStyle: AppText.uiTab,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // cards
      cardTheme: CardThemeData(
        color: AppColors.sand0,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        margin: EdgeInsets.zero,
      ),

      // chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand2,
        selectedColor: AppColors.ink,
        labelStyle: AppText.uiTab.copyWith(color: AppColors.ink2),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      ),

      // elevated button (CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: AppText.uiCta,
          elevation: 0,
        ),
      ),

      // outlined button (ghost)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          side: BorderSide(color: AppColors.line),
          textStyle: AppText.uiCta.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
      ),

      // text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sand0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        hintStyle: AppText.uiBody.copyWith(color: AppColors.ink3),
        labelStyle: AppText.monoSm.copyWith(color: AppColors.ink3, fontSize: 11),
      ),

      // divider
      dividerTheme: const DividerThemeData(
        color: AppColors.line, thickness: 1, space: 0,
      ),
    );
    return base;
  }

  // ══════════════════════════════════════════════════════════════
  // DARK THEME (Night mode)
  // ══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.coral,
      colorScheme: ColorScheme.dark(
        primary:        AppColors.coral,
        secondary:      AppColors.blueBright,
        surface:        AppColors.nightSurface0,
        onPrimary:      Colors.white,
        onSurface:      AppColors.nightInk,
        outline:        Colors.white.withOpacity(0.10),
      ),
      textTheme: _textTheme(AppColors.nightInk),
      fontFamily: GoogleFonts.schibstedGrotesk().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.nightInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppText.dispH2(20).copyWith(color: AppColors.nightInk),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.nightSurface0.withOpacity(0.88),
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.nightInk3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.nightSurface0,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: AppText.uiCta,
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightSurface0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        hintStyle: AppText.uiBody.copyWith(color: AppColors.nightInk3),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.10), thickness: 1, space: 0,
      ),
    );
    return base;
  }

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
