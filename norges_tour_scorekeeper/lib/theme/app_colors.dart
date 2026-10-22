import 'package:flutter/material.dart';

/// SpikeDunk · Norges Tour — fargetokens for dommerappen (mørkt tema).
class AppColors {
  AppColors._();

  // ── Ink (standardfarge i tekststilene) ────────────────────────
  static const Color ink   = Color(0xFF0B1B33);
  static const Color ink2  = Color(0xFF566175);
  static const Color ink3  = Color(0xFF9AA1AE);

  // ── Merkefarger ───────────────────────────────────────────────
  /// Hovedaksent — live, knapper, poeng
  static const Color coral      = Color(0xFFFF4B4B);

  /// Sekundæraksent
  static const Color blue       = Color(0xFF3B82F6);
  static const Color blueBright = Color(0xFF60A5FA);

  static const Color green      = Color(0xFF10B981);

  // ── Mørke flater og tekst ────────────────────────────────────
  static const Color nightSurface0 = Color(0xFF090F1A); // Dypeste bakgrunn
  static const Color nightSurface1 = Color(0xFF111C2E); // Kort og menyer
  static const Color nightSurface2 = Color(0xFF1A2A44); // Hevede kort og chips
  static const Color nightInk      = Color(0xFFFFFFFF); // Hvit hovedtekst
  static const Color nightInk2     = Color(0xFF94A3B8); // Dempet tekst
  static const Color nightInk3     = Color(0xFF64748B); // Plassholdere
}
