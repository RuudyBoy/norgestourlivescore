import 'package:flutter/material.dart';

/// SpikeDunk · Norges Tour — Colour tokens
/// Matches the new premium dark-theme design system.
/// Usage: AppColors.coral, AppColors.nightSurface0, etc.
class AppColors {
  AppColors._();

  // ── Sand canvas (Legacy Light Theme) ──────────────────────────
  static const Color sand0 = Color(0xFFFBF6EE);
  static const Color sand1 = Color(0xFFF4EADB);
  static const Color sand2 = Color(0xFFE7D7C0);

  // ── Ink (text + icon - Legacy Light Theme) ────────────────────
  static const Color ink   = Color(0xFF0B1B33);
  static const Color ink2  = Color(0xFF566175);
  static const Color ink3  = Color(0xFF9AA1AE);

  // ── Brand accents ─────────────────────────────────────────────
  /// Primary accent — live indicator, CTAs, scores, coral fills
  static const Color coral      = Color(0xFFFF4B4B); // Brighter coral
  static const Color coralDeep  = Color(0xFFD83A3A);
  static const Color coralGlow  = Color(0x66FF4B4B); // 40% alpha

  /// Secondary accent — tour info, stat bars, links
  static const Color blue       = Color(0xFF3B82F6); // Lighter, more electric blue
  static const Color blueBright = Color(0xFF60A5FA);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color green      = Color(0xFF10B981);
  static const Color greenLight = Color(0x3310B981); // 20% alpha

  /// Divider / border
  static const Color line       = Color(0x1A0B1B33); // 10% ink

  // ── Dark-theme overrides (Night mode) ────────────────────────
  // Much darker and richer blues/blacks
  static const Color nightSurface0 = Color(0xFF090F1A); // Deepest background
  static const Color nightSurface1 = Color(0xFF111C2E); // Cards, menus
  static const Color nightSurface2 = Color(0xFF1A2A44); // Elevated cards, chips
  static const Color nightInk      = Color(0xFFFFFFFF); // Bright white for primary text
  static const Color nightInk2     = Color(0xFF94A3B8); // Muted text (slate-400)
  static const Color nightInk3     = Color(0xFF64748B); // Placeholders (slate-500)

  // ── Gradient helpers ─────────────────────────────────────────
  static const LinearGradient heroNavy = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF111C2E), Color(0xFF1A2A44), Color(0xFF090F1A)],
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient heroCoral = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFF4B4B), Color(0xFFD83A3A), Color(0xFF991B1B)],
    stops: [0.0, 0.60, 1.0],
  );
  static const LinearGradient heroMix = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF111C2E), Color(0xFF1A2A44), Color(0xFF991B1B)],
    stops: [0.0, 0.45, 1.2],
  );
  static const LinearGradient cardInk = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A2A44), Color(0xFF090F1A)],
  );
}
