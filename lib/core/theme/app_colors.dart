import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Warm charcoal backgrounds — matches logo's dark luxe base
  static const backgroundDark = Color(0xFF0D0B0A);
  static const backgroundMid = Color(0xFF151210);
  static const backgroundLight = Color(0xFF1E1A17);
  static const surface = Color(0xFF252019);
  static const surfaceElevated = Color(0xFF2C2620);
  static const authSheet = Color(0xFF141110);

  static const primary = Color(0xFF8B6FFF);
  static const primaryLight = Color(0xFFA894FF);
  static const primaryDark = Color(0xFF5A3FD4);

  // Rose-gold metallic accent — aligned with CATCHY logo
  static const accent = Color(0xFFD4A574);
  static const accentLight = Color(0xFFEDC896);
  static const accentDark = Color(0xFFA67B45);

  static const textPrimary = Color(0xFFF8F4EF);
  static const textSecondary = Color(0xFFC9BFB4);
  static const textMuted = Color(0xFF8A8078);

  static const glassFill = Color(0x33FFFFFF);
  static const glassBorder = Color(0x40FFFFFF);
  static const glassHighlight = Color(0x1AFFFFFF);
  static const glassInnerGlow = Color(0x0DFFFFFF);

  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);

  static const glowPurple = Color(0xFF7C5CFF);
  static const glowAccent = Color(0xFFC9A06A);
  static const glowRose = Color(0xFFD4A574);

  static const gradientColors = [
    backgroundDark,
    backgroundMid,
    backgroundLight,
  ];

  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get authGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF3D2E22),
          Color(0xFF151210),
          Color(0xFF0A0908),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primary, primaryDark],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentLight, accent, accentDark],
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get glassShine => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      );

  static List<BoxShadow> cardShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? glowAccent).withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
