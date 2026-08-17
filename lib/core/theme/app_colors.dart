import 'package:flutter/material.dart';

/// CATCHY Option B v2 — Soft Luxury brand tokens.
///
/// Mode-specific surfaces and text live on [AppThemeExtension] via
/// `context.appColors`. Brand and status tokens here are shared; prefer
/// extension `primary` / `accent` when light vs dark CTA hues differ.
class AppColors {
  AppColors._();

  // --- Radii (v2 chrome) ---
  static const radiusControl = 12.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 24.0;

  // --- Dark neutrals (default / dark mode) ---
  static const backgroundDark = Color(0xFF0E0D0C);
  static const backgroundMid = Color(0xFF161412);
  static const backgroundLight = Color(0xFF1A1816);
  static const surface = Color(0xFF1A1816);
  static const surfaceElevated = Color(0xFF22201C);
  static const surfaceSunken = Color(0xFF12110F);
  static const authSheet = Color(0xFF1A1816);

  // --- Brand purple (light CTA default; dark uses primaryLight) ---
  static const primary = Color(0xFF6B5CE0);
  static const primaryLight = Color(0xFF8B7FF0);
  static const primaryDark = Color(0xFF5548C4);
  static const primarySoftLight = Color(0xFFF0EEFA);
  static const primarySoftDark = Color(0xFF242038);

  // --- Rose accent (default; overridable via AccentPalette) ---
  static const accent = Color(0xFFC96F7D);
  static const accentLight = Color(0xFFE0909D);
  static const accentDark = Color(0xFFA95361);
  static const accentSoftLight = Color(0xFFFBECEF);
  static const accentSoftDark = Color(0xFF321D22);

  // --- Dark text (legacy static; prefer context.appColors) ---
  static const textPrimary = Color(0xFFF5F2EC);
  static const textSecondary = Color(0xFFB8B2A8);
  static const textMuted = Color(0xFF7A746C);

  // --- Borders / fills (dark defaults; extension overrides per mode) ---
  static const border = Color(0xFF2E2B27);
  static const borderStrong = Color(0xFF3A3630);

  /// Opaque card fill alias (no glass). Prefer [surface] / extension.
  static const glassFill = surface;
  static const glassBorder = border;
  static const glassHighlight = Color(0x0AFFFFFF);
  static const glassInnerGlow = Color(0x00FFFFFF);

  // --- Status (muted luxury) ---
  static const success = Color(0xFF2F9B6A);
  static const warning = Color(0xFFD4A017);
  static const error = Color(0xFFD94B4B);

  /// Filled rating stars (badges, histograms, review pickers).
  static const starGold = Color(0xFFE4B84A);

  // --- Glow aliases (hairline-first; minimal tint) ---
  static const glowPurple = primary;
  static const glowAccent = accent;
  static const glowRose = accent;

  // --- Light neutrals (for static references / splash fallbacks) ---
  static const lightBackground = Color(0xFFFAF8F6);
  static const lightSubtle = Color(0xFFF3F0EC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSunken = Color(0xFFF0EDE8);
  static const lightBorder = Color(0xFFE8E4DE);
  static const lightBorderStrong = Color(0xFFD6D0C8);
  static const lightTextPrimary = Color(0xFF141210);
  static const lightTextSecondary = Color(0xFF5C574F);
  static const lightTextMuted = Color(0xFF8F887E);

  static const gradientColors = [
    backgroundDark,
    backgroundMid,
    backgroundLight,
  ];

  /// Flat app background (v2: no multi-stop wash).
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, backgroundDark],
  );

  static LinearGradient get authGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundMid, backgroundDark],
  );

  /// Solid primary (gradients retired in v2).
  static LinearGradient get primaryGradient =>
      const LinearGradient(colors: [primary, primary]);

  /// Solid accent (gradients retired in v2).
  static LinearGradient get accentGradient =>
      const LinearGradient(colors: [accent, accent]);

  /// No-op shine (glassmorphism retired).
  static LinearGradient get glassShine =>
      const LinearGradient(colors: [Colors.transparent, Colors.transparent]);

  /// Hairline-first ambient shadow (no gold glow).
  static List<BoxShadow> cardShadow({Color? color}) => [
    BoxShadow(
      color: (color ?? Colors.black).withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
