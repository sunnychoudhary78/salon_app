import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';

class SalonReviewCard extends StatelessWidget {
  const SalonReviewCard({
    super.key,
    required this.review,
    this.dateLabel,
    this.preview = false,
  });

  final ReviewModel review;
  final String? dateLabel;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initial = (review.customerName ?? 'C').substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: context.appColors.accent.withValues(alpha: 0.14),
            child: Text(
              initial,
              style: TextStyle(
                color: context.appColors.accentDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.customerName ?? 'Customer',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (dateLabel != null)
                      Text(
                        dateLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Salon',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                ReviewStarsRow(rating: review.rating, size: 15),
                if (review.staffRating != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.staffName != null
                        ? 'Staff · ${review.staffName}'
                        : 'Staff',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ReviewStarsRow(rating: review.staffRating!, size: 15),
                ],
                if (review.review != null && review.review!.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    review.review!,
                    maxLines: preview ? 3 : null,
                    overflow: preview ? TextOverflow.ellipsis : null,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
