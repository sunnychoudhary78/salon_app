import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/shared/widgets/tap_scale_wrapper.dart';

/// Solid surface card (legacy name; glassmorphism retired in v2).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = AppColors.radiusCard,
    this.elevated = true,
    this.shadowColor,
    this.animateOnMount = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  final Color? shadowColor;
  final bool animateOnMount;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: AppDecorations.glass(
        context,
        radius: radius,
        elevated: elevated,
        shadowColor: shadowColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (animateOnMount) {
      card = card.appEntrance(context: context, style: EntranceStyle.scaleIn);
    }

    if (onTap == null) return card;

    return TapScaleWrapper(onTap: onTap, child: card);
  }
}
