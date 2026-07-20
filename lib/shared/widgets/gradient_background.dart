import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

/// Flat app background (v2: no glow orbs).
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: colors.backgroundGradient),
        ),
        child,
      ],
    );
  }
}
