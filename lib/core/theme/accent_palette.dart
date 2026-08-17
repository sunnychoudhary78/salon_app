import 'package:flutter/material.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';

enum AccentPalette {
  gold,
  rose,
  emerald,
  ocean,
  violet,
  plum;

  /// Palettes the customer switcher may offer. [plum] is owner-only.
  static const customerChoices = [gold, rose, emerald, ocean, violet];

  String get label => switch (this) {
    gold => 'Gold',
    rose => 'Rose',
    emerald => 'Emerald',
    ocean => 'Ocean',
    violet => 'Violet',
    plum => 'Plum',
  };

  String get storageValue => name;

  AccentPaletteTokens get tokens => switch (this) {
    gold => const AccentPaletteTokens(
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFE2C45C),
      accentDark: Color(0xFFAA8618),
      softLight: Color(0xFFFFF8DE),
      softDark: Color(0xFF302813),
      onAccent: Color(0xFF171204),
    ),
    rose => const AccentPaletteTokens(
      accent: Color(0xFFC96F7D),
      accentLight: Color(0xFFE0909D),
      accentDark: Color(0xFFA95361),
      softLight: Color(0xFFFBECEF),
      softDark: Color(0xFF321D22),
      onAccent: Color(0xFF1D0E11),
    ),
    emerald => const AccentPaletteTokens(
      accent: Color(0xFF2F9B78),
      accentLight: Color(0xFF55BA97),
      accentDark: Color(0xFF22775B),
      softLight: Color(0xFFE6F5EF),
      softDark: Color(0xFF162D25),
      onAccent: Color(0xFF071A13),
    ),
    ocean => const AccentPaletteTokens(
      accent: Color(0xFF4F7FD8),
      accentLight: Color(0xFF79A2EC),
      accentDark: Color(0xFF365FAE),
      softLight: Color(0xFFEAF0FC),
      softDark: Color(0xFF18243A),
      onAccent: Colors.white,
    ),
    violet => const AccentPaletteTokens(
      accent: Color(0xFF8067C9),
      accentLight: Color(0xFFA18CE1),
      accentDark: Color(0xFF624AA8),
      softLight: Color(0xFFF0ECFA),
      softDark: Color(0xFF251E38),
      onAccent: Colors.white,
    ),
    plum => const AccentPaletteTokens(
      accent: Color(0xFF7A3F55),
      accentLight: Color(0xFF9A6176),
      accentDark: Color(0xFF5C2E40),
      softLight: Color(0xFFF6EBEE),
      softDark: Color(0xFF24151B),
      onAccent: Color(0xFFF8F1F3),
    ),
  };

  /// Owner sessions always use plum. The stored customer palette is left
  /// untouched so logging out restores rose/ocean/gold/etc.
  static AccentPalette forSession({
    required bool isOwner,
    required AccentPalette stored,
  }) => isOwner ? plum : stored;

  static AccentPalette fromStorage(String? value) {
    // Legacy champagne installs map to gold; unset / unknown defaults to rose.
    if (value == 'champagne') return AccentPalette.gold;
    return AccentPalette.values.firstWhere(
      (palette) => palette.storageValue == value,
      orElse: () => AccentPalette.rose,
    );
  }

  /// Accent driven by the customer Men/Women audience toggle.
  static AccentPalette forAudience(AudienceMode mode) =>
      mode == AudienceMode.women ? AccentPalette.rose : AccentPalette.ocean;
}

class AccentPaletteTokens {
  const AccentPaletteTokens({
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.softLight,
    required this.softDark,
    required this.onAccent,
  });

  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color softLight;
  final Color softDark;
  final Color onAccent;
}
