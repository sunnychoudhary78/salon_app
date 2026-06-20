import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';

/// Frosted glass panel for overlapping salon card footers.
class GlassOverlayPanel extends StatelessWidget {
  const GlassOverlayPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(16),
    ),
    this.blurSigma = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: AppDecorations.blurLayer(
        sigma: blurSigma,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 48,
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
  }
}
