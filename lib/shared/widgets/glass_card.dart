import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = 16,
    this.elevated = true,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final card = AppDecorations.blurLayer(
      sigma: 20,
      child: Container(
        margin: margin,
        decoration: AppDecorations.glass(
          radius: radius,
          elevated: elevated,
          shadowColor: shadowColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // Top-left shine highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.glassShine,
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.accent.withValues(alpha: 0.06),
        child: card,
      ),
    );
  }
}
