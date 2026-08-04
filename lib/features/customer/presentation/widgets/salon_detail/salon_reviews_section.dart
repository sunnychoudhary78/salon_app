import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_review_card.dart';
import 'package:saloon_booking/shared/widgets/rating_histogram.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';

class SalonReviewsSection extends StatelessWidget {
  const SalonReviewsSection({
    super.key,
    required this.salon,
    required this.reviewsResult,
  });

  final SalonModel salon;
  final SalonReviewsResult reviewsResult;

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(date);
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colors = sheetContext.appColors;
        final reviews = reviewsResult.reviews;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'All Reviews',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                if (salon.reviewCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: premiumCardDecoration(sheetContext),
                      child: RatingHistogram(
                        averageRating: salon.averageRating ?? 0,
                        reviewCount: salon.reviewCount,
                        starCounts: RatingHistogram.countsFromRatings(
                          reviews.map((r) => r.rating).toList(),
                        ),
                      ),
                    ),
                  ),
                if (reviewsResult.total > reviews.length)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Showing ${reviews.length} of ${reviewsResult.total} reviews',
                      style: Theme.of(
                        sheetContext,
                      ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return SalonReviewCard(
                        review: reviews[index],
                        dateLabel: reviews[index].createdAt != null
                            ? relativeDate(reviews[index].createdAt!)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reviews = reviewsResult.reviews;
    final rating = salon.averageRating;
    final hasReviews =
        reviews.isNotEmpty && salon.reviewCount > 0 && rating != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (hasReviews)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${salon.reviewCount} review${salon.reviewCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasReviews)
            const _NewSalonReviewCard()
          else ...[
            _ReviewSummaryCard(rating: rating, reviewCount: salon.reviewCount),
            const SizedBox(height: 14),
            for (final review in reviews.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SalonReviewCard(
                  review: review,
                  preview: true,
                  dateLabel: review.createdAt != null
                      ? relativeDate(review.createdAt!)
                      : null,
                ),
              ),
            if (reviews.length > 3 || reviewsResult.total > reviews.length)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAllReviews(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: colors.glassBorder.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    reviewsResult.total > reviews.length
                        ? 'View All Reviews (${reviewsResult.total})'
                        : 'View All Reviews',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.accent.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: context.appColors.accent.withValues(alpha: 0.25),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReviewStarsRow(rating: rating.round().clamp(0, 5), size: 19),
                const SizedBox(height: 5),
                Text(
                  'Based on $reviewCount review${reviewCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewSalonReviewCard extends StatelessWidget {
  const _NewSalonReviewCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.glassBorder.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: context.appColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New salon',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No reviews yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
