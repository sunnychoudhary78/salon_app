import 'package:flutter/material.dart';

/// Classic serif look for headings in the Beauty Assistant.
/// Uses system serif fonts so no extra dependency is needed.
TextStyle beautySerif(
  BuildContext context, {
  double size = 20,
  FontWeight weight = FontWeight.w600,
  Color? color,
  double? height,
  double letterSpacing = 0.2,
}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'Noto Serif', 'serif'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}