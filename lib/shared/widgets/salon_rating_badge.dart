import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

enum SalonRatingBadgeSize { compact, regular, large }

class SalonRatingBadge extends StatelessWidget {
  const SalonRatingBadge({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    this.size = SalonRatingBadgeSize.regular,
  });

  final double? averageRating;
  final int reviewCount;
  final SalonRatingBadgeSize size;

  Color get _accentColor {
    if (reviewCount == 0 || averageRating == null) {
      return AppColors.textMuted;
    }
    if (averageRating! >= 4) return AppColors.success;
    if (averageRating! >= 3) return AppColors.warning;
    return AppColors.error;
  }

  String get _ratingLabel {
    if (reviewCount == 0 || averageRating == null) return 'New';
    return averageRating!.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = size == SalonRatingBadgeSize.compact;
    final isLarge = size == SalonRatingBadgeSize.large;
    final horizontal = isCompact ? 8.0 : isLarge ? 12.0 : 10.0;
    final vertical = isCompact ? 4.0 : isLarge ? 8.0 : 6.0;
    final starSize = isCompact ? 12.0 : isLarge ? 18.0 : 14.0;
    final textStyle = isLarge
        ? Theme.of(context).textTheme.titleMedium
        : isCompact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: starSize, color: _accentColor),
          SizedBox(width: isCompact ? 3 : 4),
          Text(
            _ratingLabel,
            style: textStyle?.copyWith(
              color: _accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (reviewCount > 0) ...[
            SizedBox(width: isCompact ? 4 : 6),
            Text(
              isCompact ? '($reviewCount)' : '$reviewCount reviews',
              style: (isCompact
                      ? Theme.of(context).textTheme.labelSmall
                      : Theme.of(context).textTheme.bodySmall)
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class ReviewStarsRow extends StatelessWidget {
  const ReviewStarsRow({
    super.key,
    required this.rating,
    this.size = 18,
    this.activeColor = AppColors.accent,
  });

  final int rating;
  final double size;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: index < rating ? activeColor : AppColors.textMuted,
        );
      }),
    );
  }
}
