import 'package:flutter/material.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 64,
    this.showFrame = false,
    this.borderRadius = 20,
    this.maxWidth,
    this.showGlow = false,
  });

  final double size;
  final bool showFrame;
  final double borderRadius;
  final double? maxWidth;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? (showFrame ? size * 0.76 : size * 2.2);
    final image = Image.asset(
      AppConfig.appLogoAsset,
      height: size,
      width: width,
      fit: BoxFit.contain,
    );

    Widget content = image;

    if (showFrame) {
      content = Container(
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 4),
          child: image,
        ),
      );
    }

    if (!showGlow) return content;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width * 1.1,
          height: size * 1.15,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 48,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppColors.accentDark.withValues(alpha: 0.2),
                blurRadius: 80,
                spreadRadius: 16,
              ),
            ],
          ),
        ),
        content,
      ],
    );
  }
}
