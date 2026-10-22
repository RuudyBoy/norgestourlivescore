import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SpikeDunk · Norges Tour — typografi.
///
///   • disp…  Saira — store tall og overskrifter
///   • ui…    Schibsted Grotesk — brødtekst, etiketter og knapper
///   • mono…  IBM Plex Mono — små dataetiketter
class AppText {
  AppText._();

  // ── Saira (disp) ──────────────────────────────────────────────

  /// Stort poengtall — 42 pt kursiv black
  static TextStyle dispScore([double size = 42]) => GoogleFonts.saira(
    fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: -0.5, height: 0.88,
  );

  /// Sidetittel / stor overskrift — 30 pt kursiv black
  static TextStyle dispH1([double size = 30]) => GoogleFonts.saira(
    fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.2, height: 0.95,
  );

  /// Kortoverskrift / lagnavn — 22 pt kursiv bold
  static TextStyle dispH2([double size = 22]) => GoogleFonts.saira(
    fontWeight: FontWeight.w800, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.15, height: 1.0,
  );

  /// Seksjonskicker — 15 pt kursiv extrabold
  static TextStyle dispKicker([double size = 15]) => GoogleFonts.saira(
    fontWeight: FontWeight.w800, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.3,
  );

  // ── Schibsted Grotesk (ui) ────────────────────────────────────

  /// Brødtekst — 14 pt medium
  static TextStyle uiBody = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.ink, height: 1.45,
  );

  /// Liten undertekst — 12 pt regular
  static TextStyle uiCaption = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.ink2, height: 1.3,
  );

  /// Radtittel — 14 pt semibold
  static TextStyle uiTitle = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink, height: 1.2,
  );

  /// Knappetekst — 15 pt extrabold
  static TextStyle uiCta = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: 0.1,
  );

  // ── IBM Plex Mono (mono) ──────────────────────────────────────

  /// Liten dataetikett — 9.5 pt
  static TextStyle monoSm = GoogleFonts.ibmPlexMono(
    fontWeight: FontWeight.w500, fontSize: 9.5, letterSpacing: 1.3, color: AppColors.ink3,
  );

  /// Mellomstor data (sett, tid) — 12 pt
  static TextStyle monoMd = GoogleFonts.ibmPlexMono(
    fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.8, color: AppColors.ink2,
  );
}
