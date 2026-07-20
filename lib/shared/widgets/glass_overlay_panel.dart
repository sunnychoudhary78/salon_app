import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

/// Solid overlay panel for salon card footers (v2: no frosted glass).
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

  /// Unused; kept for call-site compatibility.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.glassBorder),
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
