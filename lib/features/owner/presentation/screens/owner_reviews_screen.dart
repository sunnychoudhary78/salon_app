import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_filter_chip.dart';
import 'package:saloon_booking/shared/widgets/rating_histogram.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerReviewsScreen extends ConsumerStatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  ConsumerState<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends ConsumerState<OwnerReviewsScreen> {
  String? _salonFilter;

  String _relativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(date);
  }

  double _averageRating(List<ReviewModel> items) {
    if (items.isEmpty) return 0;
    return items.map((r) => r.rating).reduce((a, b) => a + b) / items.length;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(ownerReviewsProvider);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Reviews',
        subtitle: reviews.maybeWhen(
          data: (items) =>
              '${items.length} review${items.length == 1 ? '' : 's'}',
          orElse: () => null,
        ),
      ),
      body: GradientBackground(
        child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ownerReviewsProvider),
        child: AsyncValueWidget(
          value: reviews,
          data: (items) {
            final salonNames =
                items
                    .map((r) => r.salonName)
                    .whereType<String>()
                    .toSet()
                    .toList()
                  ..sort();

            final filtered = _salonFilter == null
                ? items
                : items.where((r) => r.salonName == _salonFilter).toList();

            if (items.isEmpty) {
              return const EmptyStateScrollable(
                child: EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'No reviews yet',
                  subtitle:
                      'Reviews from customers will appear here after their visits.',
                ),
              );
            }

            final avgRating = _averageRating(items);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                AnimatedEntrance(
                  child: GlassCard(
                    shadowColor: context.appColors.accent,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.starGold,
                                  ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < avgRating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 18,
                                  color: AppColors.starGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall rating',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${items.length} total review${items.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.starGold.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: AppColors.starGold,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: 1,
                  child: GlassCard(
                    child: RatingHistogram(
                      averageRating: avgRating,
                      reviewCount: items.length,
                      starCounts: RatingHistogram.countsFromRatings(
                        items.map((r) => r.rating).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const AnimatedEntrance(
                  index: 2,
                  child: SectionHeader(
                    title: 'Customer feedback',
                    subtitle: 'Ratings from your salon visits',
                  ),
                ),
                if (salonNames.length > 1) ...[
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    index: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          PremiumFilterChip(
                            label: 'All salons',
                            selected: _salonFilter == null,
                            onTap: () => setState(() => _salonFilter = null),
                          ),
                          ...salonNames.map(
                            (name) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: PremiumFilterChip(
                                label: name,
                                selected: _salonFilter == name,
                                onTap: () =>
                                    setState(() => _salonFilter = name),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No reviews for this salon',
                    compact: true,
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final review = entry.value;
                    return AnimatedEntrance(
                      index: 3 + entry.key,
                      child: _ReviewCard(
                        review: review,
                        relativeDate: _relativeDate(review.createdAt),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.relativeDate});

  final ReviewModel review;
  final String relativeDate;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      elevated: true,
      radius: 18,
      shadowColor: context.appColors.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.accent,
                  context.appColors.accent.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (review.customerName ?? 'C')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: context.appColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.customerName ?? 'Customer',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (relativeDate.isNotEmpty)
                            Text(
                              relativeDate,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (j) => Icon(
                          j < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: AppColors.starGold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.staffRating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        review.staffName != null
                            ? 'Staff · ${review.staffName}'
                            : 'Staff',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (j) => Icon(
                            j < review.staffRating!
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: AppColors.starGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (review.salonName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.appColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      review.salonName!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (review.review != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${review.review!}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
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
