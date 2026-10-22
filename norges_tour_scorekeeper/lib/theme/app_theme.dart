import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// SpikeDunk · Norges Tour — ThemeData for dommerappen (bare mørkt tema).
class AppTheme {
  AppTheme._();

  // ── Radier ─────────────────────────────────────
  static const double radiusCard   = 24.0;
  static const double radiusInput  = 16.0;
  static const double radiusButton = 16.0;

  // ── Skygger ───────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3,  offset: const Offset(0, 1)),
  ];

  // ══════════════════════════════════════════════════════════════
  // MØRKT TEMA
  // ══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.nightSurface0,
      primaryColor: AppColors.coral,
      colorScheme: ColorScheme.dark(
        primary:        AppColors.coral,
        secondary:      AppColors.blueBright,
        surface:        AppColors.nightSurface1,
        onPrimary:      Colors.white,
        onSurface:      AppColors.nightInk,
        outline:        Colors.white.withValues(alpha: 0.05),
      ),
      textTheme: _textTheme(AppColors.nightInk),
      fontFamily: GoogleFonts.inter().fontFamily ?? GoogleFonts.schibstedGrotesk().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.nightInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppText.dispH2(20).copyWith(color: AppColors.nightInk, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.nightSurface1.withValues(alpha: 0.95),
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
          minimumSize: const Size.fromHeight(56),
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
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          textStyle: AppText.uiCta.copyWith(color: AppColors.nightInk, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightSurface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        hintStyle: AppText.uiBody.copyWith(color: AppColors.nightInk3),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.05), thickness: 1, space: 0,
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

  // ── Tekststiler i temaet ─────────────────────────────────────────
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
    bodySmall:     AppText.uiCaption.copyWith(color: color.withValues(alpha: 0.7)),
    labelLarge:    AppText.uiCta.copyWith(color: color),
    labelMedium:   AppText.monoMd.copyWith(color: color),
    labelSmall:    AppText.monoSm.copyWith(color: color),
  );
}
