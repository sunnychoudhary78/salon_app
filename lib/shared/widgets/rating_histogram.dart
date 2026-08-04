import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class RatingHistogram extends StatelessWidget {
  const RatingHistogram({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    this.starCounts,
  });

  final double averageRating;
  final int reviewCount;
  final Map<int, int>? starCounts;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final counts = starCounts ?? _emptyCounts();
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: context.appColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final filled = i < averageRating.round();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: context.appColors.accent,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$reviewCount review${reviewCount == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = counts[star] ?? 0;
              final fraction = maxCount > 0 ? count / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: context.appColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: colors.glassBorder.withValues(
                            alpha: 0.3,
                          ),
                          color: context.appColors.accent.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      child: Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static Map<int, int> countsFromRatings(List<int> ratings) {
    final counts = _emptyCounts();
    for (final rating in ratings) {
      final clamped = rating.clamp(1, 5);
      counts[clamped] = (counts[clamped] ?? 0) + 1;
    }
    return counts;
  }

  static Map<int, int> _emptyCounts() => {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
}
